<script>
import { GlButton, GlLoadingIcon, GlSprintf, GlAlert, GlLink } from '@gitlab/ui';
import { escape } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { IdState } from 'vendor/vue-virtual-scroller';
import DiffContent from 'jh_else_ce/diffs/components/diff_content.vue';
import { createAlert } from '~/alert';
import { hasDiff } from '~/helpers/diffs_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import { diffViewerErrors } from '~/ide/constants';
import { scrollToElement, isElementStuck } from '~/lib/utils/common_utils';
import { sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import notesEventHub from '~/notes/event_hub';
import DiffFileDrafts from '~/batch_comments/components/diff_file_drafts.vue';
import NoteForm from '~/notes/components/note_form.vue';
import diffLineNoteFormMixin from '~/notes/mixins/diff_line_note_form';

import { fileContentsId } from '~/diffs/components/diff_row_utils';
import {
  DIFF_FILE_AUTOMATIC_COLLAPSE,
  DIFF_FILE_MANUAL_COLLAPSE,
  EVT_EXPAND_ALL_FILES,
  EVT_PERF_MARK_DIFF_FILES_END,
  EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN,
  FILE_DIFF_POSITION_TYPE,
} from '../constants';
import eventHub from '../event_hub';
import { DIFF_FILE, SOMETHING_WENT_WRONG, SAVING_THE_COMMENT_FAILED, CONFLICT_TEXT } from '../i18n';
import { collapsedType, getShortShaFromFile } from '../utils/diff_file';
import DiffDiscussions from './diff_discussions.vue';
import DiffFileHeader from './diff_file_header.vue';

export default {
  components: {
    DiffFileHeader,
    DiffContent,
    GlButton,
    GlLoadingIcon,
    GlSprintf,
    GlAlert,
    GlLink,
    DiffFileDrafts,
    NoteForm,
    DiffDiscussions,
  },
  directives: {
    SafeHtml,
  },
  mixins: [
    glFeatureFlagsMixin(),
    IdState({ idProp: (vm) => vm.file.file_hash }),
    diffLineNoteFormMixin,
  ],
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
    codequalityData: {
      type: Object,
      required: false,
      default: null,
    },
    sastData: {
      type: Object,
      required: false,
      default: null,
    },
  },
  idState() {
    return {
      isLoadingCollapsedDiff: false,
      hasLoadedCollapsedDiff: false,
      forkMessageVisible: false,
      hasToggled: false,
    };
  },
  i18n: {
    ...DIFF_FILE,
    genericError: SOMETHING_WENT_WRONG,
  },
  computed: {
    ...mapState('diffs', ['currentDiffFileId', 'conflictResolutionPath', 'canMerge']),
    ...mapGetters(['isNotesFetched', 'getNoteableData', 'noteableType']),
    ...mapGetters('diffs', ['getDiffFileDiscussions', 'isVirtualScrollingEnabled', 'pinnedFile']),
    isPinnedFile() {
      return this.file === this.pinnedFile;
    },
    viewBlobHref() {
      return escape(this.file.view_path);
    },
    shortSha() {
      return getShortShaFromFile(this.file);
    },
    showLoadingIcon() {
      return this.idState.isLoadingCollapsedDiff;
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
    forcedOpen() {
      return this.file.viewer.forceOpen;
    },
    showBody() {
      return !this.isCollapsed || this.automaticallyCollapsed;
    },
    showWarning() {
      return this.isCollapsed && this.automaticallyCollapsed && !this.viewDiffsFileByFile;
    },
    expandableWarning() {
      return this.file.viewer?.generated
        ? this.$options.i18n.autoCollapsedGenerated
        : this.$options.i18n.autoCollapsed;
    },
    showContent() {
      return !this.isCollapsed && !this.isFileTooLarge;
    },
    showLocalFileReviews() {
      return Boolean(gon.current_user_id);
    },
    isCollapsed() {
      if (this.forcedOpen) {
        return false;
      }

      if (collapsedType(this.file) !== DIFF_FILE_MANUAL_COLLAPSE) {
        return this.viewDiffsFileByFile ? false : this.file.viewer?.automaticallyCollapsed;
      }

      return this.file.viewer?.manuallyCollapsed;
    },
    fileDiscussions() {
      return this.file.discussions.filter(
        (f) => f.position?.position_type === FILE_DIFF_POSITION_TYPE,
      );
    },
    showFileDiscussions() {
      return (
        !this.file.viewer?.manuallyCollapsed &&
        (this.fileDiscussions.length || this.file.drafts?.length || this.file.hasCommentForm)
      );
    },
    diffFileHash() {
      return this.file.file_hash;
    },
    fileId() {
      return fileContentsId(this.file);
    },
  },
  watch: {
    'file.id': {
      handler: function fileIdHandler() {
        this.manageViewedEffects();
      },
    },
    'file.file_hash': {
      handler: function hashChangeWatch(newHash, oldHash) {
        if (
          this.viewDiffsFileByFile &&
          !this.isCollapsed &&
          !this.glFeatures.singleFileFileByFile &&
          newHash &&
          oldHash &&
          !this.hasDiff &&
          !this.idState.hasLoadedCollapsedDiff
        ) {
          this.requestDiff();
        }
      },
    },
  },
  created() {
    notesEventHub.$on(`loadCollapsedDiff/${this.file.file_hash}`, this.requestDiff);
    eventHub.$on(EVT_EXPAND_ALL_FILES, this.expandAllListener);
  },
  mounted() {
    if (this.hasDiff) {
      this.postRender();
    }

    this.manageViewedEffects();

    if (this.viewDiffsFileByFile) {
      requestIdleCallback(() => {
        this.prefetchFileNeighbors();
      });
    }
  },
  beforeDestroy() {
    eventHub.$off(EVT_EXPAND_ALL_FILES, this.expandAllListener);
  },
  methods: {
    ...mapActions('diffs', [
      'loadCollapsedDiff',
      'assignDiscussionsToDiff',
      'prefetchFileNeighbors',
      'setFileCollapsedByUser',
      'saveDiffDiscussion',
      'toggleFileCommentForm',
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

      if (this.isFirstFile || this.viewDiffsFileByFile) {
        eventsForThisFile.push(EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN);
      }

      if (this.isLastFile || this.viewDiffsFileByFile) {
        eventsForThisFile.push(EVT_PERF_MARK_DIFF_FILES_END);
      }

      await this.$nextTick();

      eventsForThisFile.forEach((event) => {
        eventHub.$emit(event);
      });
    },
    handleToggle({ viaUserInteraction = false } = {}) {
      const collapsingNow = !this.isCollapsed;
      const contentElement = this.$el.querySelector(`#${fileContentsId(this.file)}`);

      this.setFileCollapsedByUser({
        filePath: this.file.file_path,
        collapsed: collapsingNow,
      });

      if (
        collapsingNow &&
        viaUserInteraction &&
        contentElement &&
        isElementStuck(this.$refs.header.$el)
      ) {
        scrollToElement(contentElement, { duration: 0 });
      }

      if (!this.hasDiff && !collapsingNow) {
        this.requestDiff();
      }
    },
    requestDiff(params = {}) {
      const { idState, file } = this;

      idState.isLoadingCollapsedDiff = true;

      this.loadCollapsedDiff({ file, params })
        .then(() => {
          idState.isLoadingCollapsedDiff = false;
          idState.hasLoadedCollapsedDiff = true;
        })
        .then(() => {
          if (this.file.file_hash !== file.file_hash) return;

          requestIdleCallback(
            () => {
              this.postRender();
              this.assignDiscussionsToDiff(this.getDiffFileDiscussions(this.file));
            },
            { timeout: 1000 },
          );
        })
        .catch(() => {
          idState.isLoadingCollapsedDiff = false;
          createAlert({
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
    handleSaveNote(note, parentElement, errorCallback) {
      this.saveDiffDiscussion({
        note,
        formData: {
          noteableData: this.getNoteableData,
          noteableType: this.noteableType,
          diffFile: this.file,
          positionType: FILE_DIFF_POSITION_TYPE,
        },
      }).catch((e) => {
        const reason = e.response?.data?.errors;
        const errorMessage = reason
          ? sprintf(SAVING_THE_COMMENT_FAILED, { reason })
          : SOMETHING_WENT_WRONG;

        createAlert({
          message: errorMessage,
          parent: parentElement,
        });

        errorCallback();
      });
    },
    handleSaveDraftNote(note, _, parentElement, errorCallback) {
      this.addToReview(note, this.$options.FILE_DIFF_POSITION_TYPE, parentElement, errorCallback);
    },
  },
  CONFLICT_TEXT,
  FILE_DIFF_POSITION_TYPE,
  generatedDiffFileDocsPath: helpPagePath('user/project/merge_requests/changes.html', {
    anchor: 'collapse-generated-files',
  }),
};
</script>

<template>
  <div
    :id="file.file_hash"
    :class="{
      'comments-disabled': Boolean(file.brokenSymlink),
      'has-body': showBody,
      'is-virtual-scrolling': isVirtualScrollingEnabled,
      'pinned-file': isPinnedFile,
    }"
    :data-path="file.new_path"
    class="diff-file file-holder gl-border-none gl-mb-0! gl-pb-5"
  >
    <diff-file-header
      ref="header"
      :can-current-user-fork="canCurrentUserFork"
      :diff-file="file"
      :collapsible="true"
      :reviewed="reviewed"
      :expanded="!isCollapsed"
      :add-merge-request-buttons="true"
      :view-diffs-file-by-file="viewDiffsFileByFile"
      :show-local-file-reviews="showLocalFileReviews"
      :pinned="isPinnedFile"
      class="js-file-title file-title gl-border-1 gl-border-solid gl-border-gray-100"
      :class="[hasBodyClasses.header, { 'gl-border-red-500! gl-bg-red-200!': file.conflict_type }]"
      @toggleFile="handleToggle({ viaUserInteraction: true })"
      @showForkMessage="showForkMessage"
    />

    <div
      v-if="idState.forkMessageVisible"
      class="js-file-fork-suggestion-section file-fork-suggestion gl-border-1 gl-border-solid gl-border-gray-100 gl-border-top-0"
    >
      <span v-safe-html="forkMessage" class="file-fork-suggestion-note"></span>
      <gl-button
        :href="file.fork_path"
        class="js-fork-suggestion-button gl-mr-3"
        category="secondary"
        variant="confirm"
        >{{ $options.i18n.fork }}</gl-button
      >
      <gl-button
        class="js-cancel-fork-suggestion-button"
        category="secondary"
        @click="hideForkMessage"
      >
        {{ $options.i18n.cancel }}
      </gl-button>
    </div>
    <template v-else>
      <div
        :id="fileId"
        :class="[hasBodyClasses.contentByHash, { 'gl-border-red-500': file.conflict_type }]"
        class="diff-content"
        data-testid="content-area"
      >
        <gl-alert
          v-if="!showLoadingIcon && file.conflict_type"
          variant="danger"
          :dismissible="false"
          data-testid="conflictsAlert"
        >
          {{ $options.CONFLICT_TEXT[file.conflict_type] }}
          <template v-if="!canMerge">
            {{ __('Ask someone with write access to resolve it.') }}
          </template>
          <gl-sprintf
            v-else-if="conflictResolutionPath"
            :message="
              __(
                'You can %{gitlabLinkStart}resolve conflicts on GitLab%{gitlabLinkEnd} or %{resolveLocallyStart}resolve them locally%{resolveLocallyEnd}.',
              )
            "
          >
            <template #gitlabLink="{ content }">
              <gl-button
                :href="conflictResolutionPath"
                variant="link"
                class="gl-vertical-align-text-bottom"
                >{{ content }}</gl-button
              >
            </template>
            <template #resolveLocally="{ content }">
              <gl-button
                variant="link"
                class="gl-vertical-align-text-bottom js-check-out-modal-trigger"
                >{{ content }}</gl-button
              >
            </template>
          </gl-sprintf>
          <gl-sprintf
            v-else
            :message="__('You can %{resolveLocallyStart}resolve them locally%{resolveLocallyEnd}.')"
          >
            <template #resolveLocally="{ content }">
              <gl-button
                variant="link"
                class="gl-vertical-align-text-bottom js-check-out-modal-trigger"
                >{{ content }}</gl-button
              >
            </template>
          </gl-sprintf>
        </gl-alert>
        <div v-if="showFileDiscussions" data-testid="file-discussions">
          <div class="diff-file-discussions-wrapper">
            <diff-discussions
              v-if="fileDiscussions.length"
              class="diff-file-discussions"
              data-testid="diff-file-discussions"
              :discussions="fileDiscussions"
            />
            <diff-file-drafts
              :file-hash="file.file_hash"
              :show-pin="false"
              :position-type="$options.FILE_DIFF_POSITION_TYPE"
              class="diff-file-discussions"
            />
            <note-form
              v-if="file.hasCommentForm"
              :save-button-title="__('Comment')"
              :diff-file="file"
              autofocus
              class="gl-py-3 gl-px-5"
              data-testid="file-note-form"
              @handleFormUpdate="handleSaveNote"
              @handleFormUpdateAddToReview="handleSaveDraftNote"
              @cancelForm="toggleFileCommentForm(file.file_path)"
            />
          </div>
        </div>
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
              <gl-sprintf :message="expandableWarning">
                <template #tag="{ content }">
                  <code>{{ content }}</code>
                </template>
                <template #link="{ content }">
                  <gl-link :href="$options.generatedDiffFileDocsPath" target="_blank">{{
                    content
                  }}</gl-link>
                </template>
              </gl-sprintf>
            </p>
            <gl-button data-testid="expand-button" @click.prevent="handleToggle">
              {{ $options.i18n.expand }}
            </gl-button>
          </div>
          <diff-content
            v-if="showContent"
            :class="hasBodyClasses.content"
            :codequality-data="codequalityData"
            :sast-data="sastData"
            :diff-file="file"
            :help-page-path="helpPagePath"
            @load-file="requestDiff"
          />
        </template>
      </div>
    </template>
  </div>
</template>
