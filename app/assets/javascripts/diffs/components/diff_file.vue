<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { escape } from 'lodash';
import { GlButton, GlLoadingIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { sprintf } from '~/locale';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { hasDiff } from '~/helpers/diffs_helper';
import eventHub from '../../notes/event_hub';
import DiffFileHeader from './diff_file_header.vue';
import DiffContent from './diff_content.vue';
import { diffViewerErrors } from '~/ide/constants';
import { GENERIC_ERROR, DIFF_FILE } from '../i18n';

export default {
  components: {
    DiffFileHeader,
    DiffContent,
    GlButton,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml,
  },
  mixins: [glFeatureFlagsMixin()],
  i18n: {
    genericError: GENERIC_ERROR,
    ...DIFF_FILE,
  },
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
      isCollapsed: this.file.viewer.collapsed || false,
    };
  },
  computed: {
    ...mapState('diffs', ['currentDiffFileId']),
    ...mapGetters(['isNotesFetched']),
    ...mapGetters('diffs', ['getDiffFileDiscussions']),
    viewBlobLink() {
      return sprintf(
        this.$options.i18n.blobView,
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
      return this.file.viewer.error_message;
    },
    forkMessage() {
      return sprintf(
        this.$options.i18n.editInFork,
        {
          tag_start: '<span class="js-file-fork-suggestion-section-action">',
          tag_end: '</span>',
        },
        false,
      );
    },
  },
  watch: {
    isCollapsed: function fileCollapsedWatch(newVal, oldVal) {
      if (!newVal && oldVal && !this.hasDiff) {
        this.handleLoadCollapsedDiff();
      }

      this.setFileCollapsed({ filePath: this.file.file_path, collapsed: newVal });
    },
    'file.file_hash': {
      handler: function watchFileHash() {
        if (this.viewDiffsFileByFile && this.file.viewer.collapsed) {
          this.isCollapsed = false;
          this.handleLoadCollapsedDiff();
        } else {
          this.isCollapsed = this.file.viewer.collapsed || false;
        }
      },
      immediate: true,
    },
    'file.viewer.collapsed': function setIsCollapsed(newVal) {
      if (!this.viewDiffsFileByFile) {
        this.isCollapsed = newVal;
      }
    },
  },
  created() {
    eventHub.$on(`loadCollapsedDiff/${this.file.file_hash}`, this.handleLoadCollapsedDiff);
  },
  methods: {
    ...mapActions('diffs', [
      'loadCollapsedDiff',
      'assignDiscussionsToDiff',
      'setRenderIt',
      'setFileCollapsed',
    ]),
    handleToggle() {
      if (!this.hasDiff) {
        this.handleLoadCollapsedDiff();
      } else {
        this.isCollapsed = !this.isCollapsed;
        this.setRenderIt(this.file);
      }
    },
    handleLoadCollapsedDiff() {
      this.isLoadingCollapsedDiff = true;

      this.loadCollapsedDiff(this.file)
        .then(() => {
          this.isLoadingCollapsedDiff = false;
          this.isCollapsed = false;
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
          createFlash(this.$options.i18n.genericError);
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
    }"
    :data-path="file.new_path"
    class="diff-file file-holder"
  >
    <diff-file-header
      :can-current-user-fork="canCurrentUserFork"
      :diff-file="file"
      :collapsible="true"
      :expanded="!isCollapsed"
      :add-merge-request-buttons="true"
      :view-diffs-file-by-file="viewDiffsFileByFile"
      class="js-file-title file-title"
      @toggleFile="handleToggle"
      @showForkMessage="showForkMessage"
    />

    <div v-if="forkMessageVisible" class="js-file-fork-suggestion-section file-fork-suggestion">
      <span v-safe-html="forkMessage" class="file-fork-suggestion-note"></span>
      <a
        :href="file.fork_path"
        class="js-fork-suggestion-button btn btn-grouped btn-inverted btn-success"
        >{{ $options.i18n.fork }}</a
      >
      <button
        class="js-cancel-fork-suggestion-button btn btn-grouped"
        type="button"
        @click="hideForkMessage"
      >
        {{ $options.i18n.cancel }}
      </button>
    </div>
    <gl-loading-icon v-if="showLoadingIcon" class="diff-content loading" />
    <template v-else>
      <div :id="`diff-content-${file.file_hash}`">
        <div v-if="errorMessage" class="diff-viewer">
          <div v-safe-html="errorMessage" class="nothing-here-block"></div>
        </div>
        <template v-else>
          <div
            v-show="isCollapsed"
            class="gl-p-7 gl-bg-gray-10 gl-text-center collapsed-file-warning"
          >
            <p class="gl-mb-8 gl-mt-5">
              {{ $options.i18n.collapsed }}
            </p>
            <gl-button class="gl-mb-5" data-testid="expandButton" @click="handleToggle">
              {{ $options.i18n.expand }}
            </gl-button>
          </div>
          <diff-content
            v-show="!isCollapsed && !isFileTooLarge"
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
