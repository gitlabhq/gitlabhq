<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { escape } from 'lodash';
import { GlLoadingIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, sprintf } from '~/locale';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { hasDiff } from '~/helpers/diffs_helper';
import eventHub from '../../notes/event_hub';
import DiffFileHeader from './diff_file_header.vue';
import DiffContent from './diff_content.vue';
import { diffViewerErrors } from '~/ide/constants';
import { collapsedType, isCollapsed } from '../diff_file';
import { DIFF_FILE_AUTOMATIC_COLLAPSE, DIFF_FILE_MANUAL_COLLAPSE } from '../constants';

export default {
  components: {
    DiffFileHeader,
    DiffContent,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    file: {
      type: Object,
      required: true,
    },
    canCurrentUserFork: {
      type: Boolean,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    viewDiffsFileByFile: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLoadingCollapsedDiff: false,
      forkMessageVisible: false,
      isCollapsed: isCollapsed(this.file),
    };
  },
  computed: {
    ...mapState('diffs', ['currentDiffFileId']),
    ...mapGetters(['isNotesFetched']),
    ...mapGetters('diffs', ['getDiffFileDiscussions']),
    viewBlobLink() {
      return sprintf(
        __('You can %{linkStart}view the blob%{linkEnd} instead.'),
        {
          linkStart: `<a href="${escape(this.file.view_path)}">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
    showLoadingIcon() {
      return this.isLoadingCollapsedDiff || (!this.file.renderIt && !this.isCollapsed);
    },
    hasDiff() {
      return hasDiff(this.file);
    },
    isFileTooLarge() {
      return this.file.viewer.error === diffViewerErrors.too_large;
    },
    errorMessage() {
      return !this.manuallyCollapsed ? this.file.viewer.error_message : '';
    },
    forkMessage() {
      return sprintf(
        __(
          "You're not allowed to %{tag_start}edit%{tag_end} files in this project directly. Please fork this project, make your changes there, and submit a merge request.",
        ),
        {
          tag_start: '<span class="js-file-fork-suggestion-section-action">',
          tag_end: '</span>',
        },
        false,
      );
    },
    hasBodyClasses() {
      const domParts = {
        header: 'gl-rounded-base!',
        contentByHash: '',
        content: '',
      };

      if (this.showBody) {
        domParts.header = 'gl-rounded-bottom-left-none gl-rounded-bottom-right-none';
        domParts.contentByHash =
          'gl-rounded-none gl-rounded-bottom-left-base gl-rounded-bottom-right-base gl-border-1 gl-border-t-0! gl-border-solid gl-border-gray-100';
        domParts.content = 'gl-rounded-bottom-left-base gl-rounded-bottom-right-base';
      }

      return domParts;
    },
    automaticallyCollapsed() {
      return collapsedType(this.file) === DIFF_FILE_AUTOMATIC_COLLAPSE;
    },
    manuallyCollapsed() {
      return collapsedType(this.file) === DIFF_FILE_MANUAL_COLLAPSE;
    },
    showBody() {
      return !this.isCollapsed || this.automaticallyCollapsed;
    },
    showWarning() {
      return this.isCollapsed && (this.automaticallyCollapsed && !this.viewDiffsFileByFile);
    },
    showContent() {
      return !this.isCollapsed && !this.isFileTooLarge;
    },
  },
  watch: {
    'file.file_hash': {
      handler: function hashChangeWatch(newHash, oldHash) {
        this.isCollapsed = isCollapsed(this.file);

        if (newHash && oldHash && !this.hasDiff) {
          this.requestDiff();
        }
      },
      immediate: true,
    },
    'file.viewer.automaticallyCollapsed': {
      handler: function autoChangeWatch(automaticValue) {
        if (collapsedType(this.file) !== DIFF_FILE_MANUAL_COLLAPSE) {
          this.isCollapsed = this.viewDiffsFileByFile ? false : automaticValue;
        }
      },
      immediate: true,
    },
    'file.viewer.manuallyCollapsed': {
      handler: function manualChangeWatch(manualValue) {
        if (manualValue !== null) {
          this.isCollapsed = manualValue;
        }
      },
      immediate: true,
    },
  },
  created() {
    eventHub.$on(`loadCollapsedDiff/${this.file.file_hash}`, this.requestDiff);
  },
  methods: {
    ...mapActions('diffs', [
      'loadCollapsedDiff',
      'assignDiscussionsToDiff',
      'setRenderIt',
      'setFileCollapsedByUser',
    ]),
    handleToggle() {
      const currentCollapsedFlag = this.isCollapsed;

      this.setFileCollapsedByUser({
        filePath: this.file.file_path,
        collapsed: !currentCollapsedFlag,
      });

      if (!this.hasDiff && currentCollapsedFlag) {
        this.requestDiff();
      }
    },
    requestDiff() {
      this.isLoadingCollapsedDiff = true;

      this.loadCollapsedDiff(this.file)
        .then(() => {
          this.isLoadingCollapsedDiff = false;
          this.setRenderIt(this.file);
        })
        .then(() => {
          requestIdleCallback(
            () => {
              this.assignDiscussionsToDiff(this.getDiffFileDiscussions(this.file));
            },
            { timeout: 1000 },
          );
        })
        .catch(() => {
          this.isLoadingCollapsedDiff = false;
          createFlash(__('Something went wrong on our end. Please try again!'));
        });
    },
    showForkMessage() {
      this.forkMessageVisible = true;
    },
    hideForkMessage() {
      this.forkMessageVisible = false;
    },
  },
};
</script>

<template>
  <div
    :id="file.file_hash"
    :class="{
      'is-active': currentDiffFileId === file.file_hash,
      'comments-disabled': Boolean(file.brokenSymlink),
      'has-body': showBody,
    }"
    :data-path="file.new_path"
    class="diff-file file-holder gl-border-none"
  >
    <diff-file-header
      :can-current-user-fork="canCurrentUserFork"
      :diff-file="file"
      :collapsible="true"
      :expanded="!isCollapsed"
      :add-merge-request-buttons="true"
      :view-diffs-file-by-file="viewDiffsFileByFile"
      class="js-file-title file-title gl-border-1 gl-border-solid gl-border-gray-100"
      :class="hasBodyClasses.header"
      @toggleFile="handleToggle"
      @showForkMessage="showForkMessage"
    />

    <div v-if="forkMessageVisible" class="js-file-fork-suggestion-section file-fork-suggestion">
      <span v-safe-html="forkMessage" class="file-fork-suggestion-note"></span>
      <a
        :href="file.fork_path"
        class="js-fork-suggestion-button btn btn-grouped btn-inverted btn-success"
        >{{ __('Fork') }}</a
      >
      <button
        class="js-cancel-fork-suggestion-button btn btn-grouped"
        type="button"
        @click="hideForkMessage"
      >
        {{ __('Cancel') }}
      </button>
    </div>
    <template v-else>
      <div
        :id="`diff-content-${file.file_hash}`"
        :class="hasBodyClasses.contentByHash"
        data-testid="content-area"
      >
        <gl-loading-icon
          v-if="showLoadingIcon"
          class="diff-content loading gl-my-0 gl-pt-3"
          data-testid="loader-icon"
        />
        <div v-else-if="errorMessage" class="diff-viewer">
          <div v-safe-html="errorMessage" class="nothing-here-block"></div>
        </div>
        <template v-else>
          <div v-show="showWarning" class="nothing-here-block diff-collapsed">
            {{ __('This diff is collapsed.') }}
            <a
              class="click-to-expand"
              data-testid="toggle-link"
              href="#"
              @click.prevent="handleToggle"
            >
              {{ __('Click to expand it.') }}
            </a>
          </div>
          <diff-content
            v-show="showContent"
            :class="hasBodyClasses.content"
            :diff-file="file"
            :help-page-path="helpPagePath"
          />
        </template>
      </div>
    </template>
  </div>
</template>

<style>
@keyframes shadow-fade {
  from {
    box-shadow: 0 0 4px #919191;
  }

  to {
    box-shadow: 0 0 0 #dfdfdf;
  }
}

.diff-file.is-active {
  box-shadow: 0 0 0 #dfdfdf;
  animation: shadow-fade 1.2s 0.1s 1;
}
</style>
