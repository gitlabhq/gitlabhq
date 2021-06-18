<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { mapParallel } from 'ee_else_ce/diffs/components/diff_row_utils';
import DiffFileDrafts from '~/batch_comments/components/diff_file_drafts.vue';
import draftCommentsMixin from '~/diffs/mixins/draft_comments';
import { diffViewerModes } from '~/ide/constants';
import diffLineNoteFormMixin from '~/notes/mixins/diff_line_note_form';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import NoPreviewViewer from '~/vue_shared/components/diff_viewer/viewers/no_preview.vue';
import NotDiffableViewer from '~/vue_shared/components/diff_viewer/viewers/not_diffable.vue';
import NoteForm from '../../notes/components/note_form.vue';
import eventHub from '../../notes/event_hub';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import { IMAGE_DIFF_POSITION_TYPE } from '../constants';
import { getDiffMode } from '../store/utils';
import DiffDiscussions from './diff_discussions.vue';
import DiffView from './diff_view.vue';
import ImageDiffOverlay from './image_diff_overlay.vue';

export default {
  components: {
    GlLoadingIcon,
    DiffView,
    DiffViewer,
    NoteForm,
    DiffDiscussions,
    ImageDiffOverlay,
    NotDiffableViewer,
    NoPreviewViewer,
    userAvatarLink,
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
  },
  computed: {
    ...mapState('diffs', ['projectPath']),
    ...mapGetters('diffs', [
      'isInlineView',
      'getCommentFormForDiffFile',
      'diffLines',
      'fileLineCodequality',
    ]),
    ...mapGetters(['getNoteableData', 'noteableType', 'getUserData']),
    diffMode() {
      return getDiffMode(this.diffFile);
    },
    diffViewerMode() {
      return this.diffFile.viewer.name;
    },
    isTextFile() {
      return this.diffViewerMode === diffViewerModes.text;
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
      return this.imageDiscussions.length || this.diffFileCommentForm;
    },
    diffFileHash() {
      return this.diffFile.file_hash;
    },
    author() {
      return this.getUserData;
    },
    mappedLines() {
      // TODO: Do this data generation when we recieve a response to save a computed property being created
      return this.diffLines(this.diffFile).map(mapParallel(this)) || [];
    },
  },
  updated() {
    this.$nextTick(() => {
      eventHub.$emit('showBlobInteractionZones', this.diffFile.new_path);
    });
  },
  methods: {
    ...mapActions('diffs', ['saveDiffDiscussion', 'closeDiffFileCommentForm']),
    handleSaveNote(note) {
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
      });
    },
  },
};
</script>

<template>
  <div class="diff-content">
    <div class="diff-viewer">
      <template v-if="isTextFile">
        <diff-view
          :diff-file="diffFile"
          :diff-lines="mappedLines"
          :help-page-path="helpPagePath"
          :inline="isInlineView"
        />
        <gl-loading-icon v-if="diffFile.renderingLines" size="md" class="mt-3" />
      </template>
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
          <user-avatar-link
            v-if="diffFileCommentForm && author"
            :link-href="author.path"
            :img-src="author.avatar_url"
            :img-alt="author.name"
            :img-size="40"
            class="d-none d-sm-block new-comment"
          />
          <diff-discussions
            v-if="diffFile.discussions.length"
            class="diff-file-discussions"
            :discussions="diffFile.discussions"
            :should-collapse-discussions="true"
            :render-avatar-badge="true"
          />
          <diff-file-drafts :file-hash="diffFileHash" class="diff-file-discussions" />
          <note-form
            v-if="diffFileCommentForm"
            ref="noteForm"
            :is-editing="false"
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
