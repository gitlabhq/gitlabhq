<script>
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { mapParallel } from 'ee_else_ce/diffs/components/diff_row_utils';
import DiffFileDrafts from '~/batch_comments/components/diff_file_drafts.vue';
import draftCommentsMixin from '~/diffs/mixins/draft_comments';
import { diffViewerModes } from '~/ide/constants';
import diffLineNoteFormMixin from '~/notes/mixins/diff_line_note_form';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import NoPreviewViewer from '~/vue_shared/components/diff_viewer/viewers/no_preview.vue';
import NotDiffableViewer from '~/vue_shared/components/diff_viewer/viewers/not_diffable.vue';
import NoteForm from '~/notes/components/note_form.vue';
import eventHub from '~/notes/event_hub';
import { IMAGE_DIFF_POSITION_TYPE } from '../constants';
import { SAVING_THE_COMMENT_FAILED, SOMETHING_WENT_WRONG } from '../i18n';
import { getDiffMode } from '../store/utils';
import DiffDiscussions from './diff_discussions.vue';
import DiffView from './diff_view.vue';
import ImageDiffOverlay from './image_diff_overlay.vue';

export default {
  components: {
    GlLoadingIcon,
    GlButton,
    DiffView,
    DiffViewer,
    NoteForm,
    DiffDiscussions,
    ImageDiffOverlay,
    NotDiffableViewer,
    NoPreviewViewer,
    DiffFileDrafts,
  },
  mixins: [diffLineNoteFormMixin, draftCommentsMixin],
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
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
    autosaveKey: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState('diffs', ['projectPath']),
    ...mapGetters('diffs', ['isInlineView', 'getCommentFormForDiffFile', 'diffLines']),
    ...mapGetters(['getNoteableData', 'noteableType', 'getUserData']),
    diffMode() {
      return getDiffMode(this.diffFile);
    },
    diffViewerMode() {
      return this.diffFile.viewer.name;
    },
    isTextFile() {
      return this.diffViewerMode === diffViewerModes.text && !this.diffFile.viewer.whitespace_only;
    },
    isWhitespaceOnly() {
      return this.diffFile.viewer.whitespace_only;
    },
    noPreview() {
      return this.diffViewerMode === diffViewerModes.no_preview;
    },
    notDiffable() {
      return this.diffViewerMode === diffViewerModes.not_diffable;
    },
    diffFileCommentForm() {
      return this.getCommentFormForDiffFile(this.diffFileHash);
    },
    showNotesContainer() {
      return (
        this.diffViewerMode === diffViewerModes.image &&
        (this.imageDiscussionsWithDrafts.length || this.diffFileCommentForm)
      );
    },
    diffFileHash() {
      return this.diffFile.file_hash;
    },
    author() {
      return this.getUserData;
    },
    mappedLines() {
      const {
        diffFile,
        codequalityData,
        sastData,
        hasParallelDraftLeft,
        hasParallelDraftRight,
        draftsForLine,
      } = this;
      return (
        this.diffLines(this.diffFile).map(
          mapParallel({
            diffFile,
            codequalityData,
            sastData,
            hasParallelDraftLeft,
            hasParallelDraftRight,
            draftsForLine,
          }),
        ) || []
      );
    },
    imageDiscussions() {
      return this.diffFile.discussions.filter(
        (f) => f.position?.position_type === IMAGE_DIFF_POSITION_TYPE,
      );
    },
  },
  updated() {
    this.$nextTick(() => {
      eventHub.$emit('showBlobInteractionZones', this.diffFile.new_path);
    });
  },
  methods: {
    ...mapActions('diffs', ['saveDiffDiscussion', 'closeDiffFileCommentForm']),
    handleSaveNote(note, parentElement, errorCallback) {
      this.saveDiffDiscussion({
        note,
        formData: {
          noteableData: this.getNoteableData,
          noteableType: this.noteableType,
          diffFile: this.diffFile,
          positionType: IMAGE_DIFF_POSITION_TYPE,
          x: this.diffFileCommentForm.x,
          y: this.diffFileCommentForm.y,
          width: this.diffFileCommentForm.width,
          height: this.diffFileCommentForm.height,
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
  },
  IMAGE_DIFF_POSITION_TYPE,
};
</script>

<template>
  <div class="diff-content">
    <div class="diff-viewer">
      <template v-if="isTextFile">
        <diff-view
          :diff-file="diffFile"
          :codequality-data="codequalityData"
          :sast-data="sastData"
          :diff-lines="mappedLines"
          :help-page-path="helpPagePath"
          :inline="isInlineView"
          :autosave-key="autosaveKey"
        />
        <gl-loading-icon v-if="diffFile.renderingLines" size="lg" class="mt-3" />
      </template>
      <div
        v-else-if="isWhitespaceOnly"
        class="gl-flex gl-h-13 gl-items-center gl-justify-center gl-bg-subtle"
        data-testid="diff-whitespace-only-state"
      >
        {{ __('Contains only whitespace changes.') }}
        <gl-button
          category="tertiary"
          variant="confirm"
          size="small"
          class="gl-ml-3"
          data-testid="diff-load-file-button"
          @click="$emit('load-file', { w: '0' })"
        >
          {{ __('Show changes') }}
        </gl-button>
      </div>
      <not-diffable-viewer v-else-if="notDiffable" />
      <no-preview-viewer v-else-if="noPreview" />
      <diff-viewer
        v-else
        :diff-file="diffFile"
        :diff-mode="diffMode"
        :diff-viewer-mode="diffViewerMode"
        :new-path="diffFile.new_path"
        :new-sha="diffFile.diff_refs.head_sha"
        :new-size="diffFile.new_size"
        :old-path="diffFile.old_path"
        :old-sha="diffFile.diff_refs.base_sha"
        :old-size="diffFile.old_size"
        :file-hash="diffFileHash"
        :project-path="projectPath"
        :a-mode="diffFile.a_mode"
        :b-mode="diffFile.b_mode"
      >
        <template #image-overlay="{ renderedWidth, renderedHeight }">
          <image-diff-overlay
            v-if="renderedWidth"
            :rendered-width="renderedWidth"
            :rendered-height="renderedHeight"
            :discussions="imageDiscussions"
            :file-hash="diffFileHash"
            :can-comment="getNoteableData.current_user.can_create_note && !diffFile.brokenSymlink"
          />
        </template>
        <div v-if="showNotesContainer" class="note-container">
          <diff-discussions
            v-if="imageDiscussions.length"
            class="diff-file-discussions"
            :discussions="imageDiscussions"
            should-collapse-discussions
            render-avatar-badge
          />
          <diff-file-drafts
            :file-hash="diffFileHash"
            :position-type="$options.IMAGE_DIFF_POSITION_TYPE"
            :autosave-key="autosaveKey"
            class="diff-file-discussions"
          />
          <note-form
            v-if="diffFileCommentForm"
            ref="noteForm"
            :save-button-title="__('Comment')"
            class="diff-comment-form new-note discussion-form discussion-form-container"
            @handleFormUpdateAddToReview="addToReview"
            @handleFormUpdate="handleSaveNote"
            @cancelForm="closeDiffFileCommentForm(diffFileHash)"
          />
        </div>
      </diff-viewer>
    </div>
  </div>
</template>
