<script>
import { GlButton, GlLoadingIcon, GlSafeHtmlDirective as SafeHtml, GlSprintf } from '@gitlab/ui';
import { escape } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import { IdState } from 'vendor/vue-virtual-scroller';
import createFlash from '~/flash';
import { hasDiff } from '~/helpers/diffs_helper';
import { diffViewerErrors } from '~/ide/constants';
import { scrollToElement } from '~/lib/utils/common_utils';
import { sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import notesEventHub from '../../notes/event_hub';

import {
  DIFF_FILE_AUTOMATIC_COLLAPSE,
  DIFF_FILE_MANUAL_COLLAPSE,
  EVT_EXPAND_ALL_FILES,
  EVT_PERF_MARK_DIFF_FILES_END,
  EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN,
} from '../constants';
import eventHub from '../event_hub';
import { DIFF_FILE, GENERIC_ERROR } from '../i18n';
import { collapsedType, getShortShaFromFile } from '../utils/diff_file';
import DiffContent from './diff_content.vue';
import DiffFileHeader from './diff_file_header.vue';

export default {
  components: {
    DiffFileHeader,
    DiffContent,
    GlButton,
    GlLoadingIcon,
    GlSprintf,
  },
  directives: {
    SafeHtml,
  },
  mixins: [glFeatureFlagsMixin(), IdState({ idProp: (vm) => vm.file.file_hash })],
  props: {
    file: {
      type: Object,
      required: true,
    },
    reviewed: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFirstFile: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLastFile: {
      type: Boolean,
      required: false,
      default: false,
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
    active: {
      type: Boolean,
      required: false,
      default: true,
    },
    preRender: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  idState() {
    return {
      isLoadingCollapsedDiff: false,
      forkMessageVisible: false,
      hasToggled: false,
    };
  },
  i18n: {
    ...DIFF_FILE,
    genericError: GENERIC_ERROR,
  },
  computed: {
    ...mapState('diffs', ['currentDiffFileId', 'codequalityDiff']),
    ...mapGetters(['isNotesFetched']),
    ...mapGetters('diffs', ['getDiffFileDiscussions', 'isVirtualScrollingEnabled']),
    viewBlobHref() {
      return escape(this.file.view_path);
    },
    shortSha() {
      return getShortShaFromFile(this.file);
    },
    showLoadingIcon() {
      return this.idState.isLoadingCollapsedDiff || (!this.file.renderIt && !this.isCollapsed);
    },
    hasDiff() {
      return hasDiff(this.file);
    },
    isFileTooLarge() {
      return !this.manuallyCollapsed && this.file.viewer.error === diffViewerErrors.too_large;
    },
    errorMessage() {
      return !this.manuallyCollapsed ? this.file.viewer.error_message : '';
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
      return this.isCollapsed && this.automaticallyCollapsed && !this.viewDiffsFileByFile;
    },
    showContent() {
      return !this.isCollapsed && !this.isFileTooLarge;
    },
    showLocalFileReviews() {
      const loggedIn = Boolean(gon.current_user_id);
      const featureOn = this.glFeatures.localFileReviews;

      return loggedIn && featureOn;
    },
    codequalityDiffForFile() {
      return this.codequalityDiff?.files?.[this.file.file_path] || [];
    },
    isCollapsed() {
      if (collapsedType(this.file) !== DIFF_FILE_MANUAL_COLLAPSE) {
        return this.viewDiffsFileByFile ? false : this.file.viewer?.automaticallyCollapsed;
      }

      return this.file.viewer?.manuallyCollapsed;
    },
  },
  watch: {
    'file.id': {
      handler: function fileIdHandler() {
        if (this.preRender) return;

        this.manageViewedEffects();
      },
    },
    'file.file_hash': {
      handler: function hashChangeWatch(newHash, oldHash) {
        if (newHash && oldHash && !this.hasDiff && !this.preRender) {
          this.requestDiff();
        }
      },
    },
  },
  created() {
    if (this.preRender) return;

    notesEventHub.$on(`loadCollapsedDiff/${this.file.file_hash}`, this.requestDiff);
    eventHub.$on(EVT_EXPAND_ALL_FILES, this.expandAllListener);
  },
  mounted() {
    if (this.preRender) return;

    if (this.hasDiff) {
      this.postRender();
    }

    this.manageViewedEffects();
  },
  beforeDestroy() {
    if (this.preRender) return;

    eventHub.$off(EVT_EXPAND_ALL_FILES, this.expandAllListener);
  },
  methods: {
    ...mapActions('diffs', [
      'loadCollapsedDiff',
      'assignDiscussionsToDiff',
      'setRenderIt',
      'setFileCollapsedByUser',
    ]),
    manageViewedEffects() {
      if (
        !this.idState.hasToggled &&
        this.reviewed &&
        !this.isCollapsed &&
        this.showLocalFileReviews
      ) {
        this.handleToggle();
        this.idState.hasToggled = true;
      }
    },
    expandAllListener() {
      if (this.isCollapsed) {
        this.handleToggle();
      }
    },
    async postRender() {
      const eventsForThisFile = [];

      if (this.isFirstFile) {
        eventsForThisFile.push(EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN);
      }

      if (this.isLastFile) {
        eventsForThisFile.push(EVT_PERF_MARK_DIFF_FILES_END);
      }

      await this.$nextTick();

      eventsForThisFile.forEach((event) => {
        eventHub.$emit(event);
      });
    },
    handleToggle({ viaUserInteraction = false } = {}) {
      const collapsingNow = !this.isCollapsed;
      const contentElement = this.$el.querySelector(`#diff-content-${this.file.file_hash}`);

      this.setFileCollapsedByUser({
        filePath: this.file.file_path,
        collapsed: collapsingNow,
      });

      if (collapsingNow && viaUserInteraction && contentElement) {
        scrollToElement(contentElement, { duration: 1 });
      }

      if (!this.hasDiff && !collapsingNow) {
        this.requestDiff();
      }
    },
    requestDiff() {
      this.idState.isLoadingCollapsedDiff = true;

      this.loadCollapsedDiff(this.file)
        .then(() => {
          this.idState.isLoadingCollapsedDiff = false;
          this.setRenderIt(this.file);
        })
        .then(() => {
          requestIdleCallback(
            () => {
              this.postRender();
              this.assignDiscussionsToDiff(this.getDiffFileDiscussions(this.file));
            },
            { timeout: 1000 },
          );
        })
        .catch(() => {
          this.idState.isLoadingCollapsedDiff = false;
          createFlash({
            message: this.$options.i18n.genericError,
          });
        });
    },
    showForkMessage() {
      this.idState.forkMessageVisible = true;
    },
    hideForkMessage() {
      this.idState.forkMessageVisible = false;
    },
  },
};
</script>

<template>
  <div
    :id="!preRender && active && file.file_hash"
    :class="{
      'is-active': currentDiffFileId === file.file_hash,
      'comments-disabled': Boolean(file.brokenSymlink),
      'has-body': showBody,
      'is-virtual-scrolling': isVirtualScrollingEnabled,
    }"
    :data-path="file.new_path"
    class="diff-file file-holder gl-border-none"
  >
    <diff-file-header
      :can-current-user-fork="canCurrentUserFork"
      :diff-file="file"
      :collapsible="true"
      :reviewed="reviewed"
      :expanded="!isCollapsed"
      :add-merge-request-buttons="true"
      :view-diffs-file-by-file="viewDiffsFileByFile"
      :show-local-file-reviews="showLocalFileReviews"
      :codequality-diff="codequalityDiffForFile"
      class="js-file-title file-title gl-border-1 gl-border-solid gl-border-gray-100"
      :class="hasBodyClasses.header"
      @toggleFile="handleToggle({ viaUserInteraction: true })"
      @showForkMessage="showForkMessage"
    />

    <div
      v-if="idState.forkMessageVisible"
      class="js-file-fork-suggestion-section file-fork-suggestion"
    >
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
    <template v-else>
      <div
        :id="!preRender && active && `diff-content-${file.file_hash}`"
        :class="hasBodyClasses.contentByHash"
        data-testid="content-area"
      >
        <gl-loading-icon
          v-if="showLoadingIcon"
          size="sm"
          class="diff-content loading gl-my-0 gl-pt-3"
          data-testid="loader-icon"
        />
        <div v-else-if="errorMessage" class="diff-viewer">
          <div
            v-if="isFileTooLarge"
            class="collapsed-file-warning gl-p-7 gl-bg-orange-50 gl-text-center gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
          >
            <p class="gl-mb-5">
              {{ $options.i18n.tooLarge }}
            </p>
            <gl-button data-testid="blob-button" category="secondary" :href="viewBlobHref">
              <gl-sprintf :message="$options.i18n.blobView">
                <template #commitSha>{{ shortSha }}</template>
              </gl-sprintf>
            </gl-button>
          </div>
          <div v-else v-safe-html="errorMessage" class="nothing-here-block"></div>
        </div>
        <template v-else>
          <div
            v-if="showWarning"
            class="collapsed-file-warning gl-p-7 gl-bg-orange-50 gl-text-center gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
          >
            <p class="gl-mb-5">
              {{ $options.i18n.autoCollapsed }}
            </p>
            <gl-button
              data-testid="expand-button"
              category="secondary"
              variant="warning"
              @click.prevent="handleToggle"
            >
              {{ $options.i18n.expand }}
            </gl-button>
          </div>
          <diff-content
            v-if="showContent"
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
