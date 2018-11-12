<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import InlineDiffView from './inline_diff_view.vue';
import ParallelDiffView from './parallel_diff_view.vue';
import NoteForm from '../../notes/components/note_form.vue';
import ImageDiffOverlay from './image_diff_overlay.vue';
import DiffDiscussions from './diff_discussions.vue';
import { IMAGE_DIFF_POSITION_TYPE } from '../constants';
import { getDiffMode } from '../store/utils';

export default {
  components: {
    InlineDiffView,
    ParallelDiffView,
    DiffViewer,
    NoteForm,
    DiffDiscussions,
    ImageDiffOverlay,
  },
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState({
      projectPath: state => state.diffs.projectPath,
      endpoint: state => state.diffs.endpoint,
    }),
    ...mapGetters('diffs', ['isInlineView', 'isParallelView']),
    ...mapGetters('diffs', ['getCommentFormForDiffFile']),
    ...mapGetters(['getNoteableData', 'noteableType']),
    diffMode() {
      return getDiffMode(this.diffFile);
    },
    isTextFile() {
      return this.diffFile.viewer.name === 'text';
    },
    diffFileCommentForm() {
      return this.getCommentFormForDiffFile(this.diffFile.fileHash);
    },
    showNotesContainer() {
      return this.diffFile.discussions.length || this.diffFileCommentForm;
    },
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
        <inline-diff-view
          v-if="isInlineView"
          :diff-file="diffFile"
          :diff-lines="diffFile.highlightedDiffLines || []"
        />
        <parallel-diff-view
          v-if="isParallelView"
          :diff-file="diffFile"
          :diff-lines="diffFile.parallelDiffLines || []"
        />
      </template>
      <diff-viewer
        v-else
        :diff-mode="diffMode"
        :new-path="diffFile.newPath"
        :new-sha="diffFile.diffRefs.headSha"
        :old-path="diffFile.oldPath"
        :old-sha="diffFile.diffRefs.baseSha"
        :file-hash="diffFile.fileHash"
        :project-path="projectPath"
      >
        <image-diff-overlay
          slot="image-overlay"
          :discussions="diffFile.discussions"
          :file-hash="diffFile.fileHash"
          :can-comment="getNoteableData.current_user.can_create_note"
        />
        <div
          v-if="showNotesContainer"
          class="note-container"
        >
          <diff-discussions
            v-if="diffFile.discussions.length"
            class="diff-file-discussions"
            :discussions="diffFile.discussions"
            :should-collapse-discussions="true"
            :render-avatar-badge="true"
          />
          <note-form
            v-if="diffFileCommentForm"
            ref="noteForm"
            :is-editing="false"
            :save-button-title="__('Comment')"
            class="diff-comment-form new-note discussion-form discussion-form-container"
            @handleFormUpdate="handleSaveNote"
            @cancelForm="closeDiffFileCommentForm(diffFile.fileHash)"
          />          
        </div>
      </diff-viewer>
    </div>
  </div>
</template>
