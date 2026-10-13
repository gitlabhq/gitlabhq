<script>
import ImageViewer from '~/rapid_diffs/app/image_viewer/image_viewer.vue';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import DraftNote from '~/rapid_diffs/app/discussions/draft_note.vue';
import BaseImageDiffOverlay from '~/diffs/components/base_image_diff_overlay.vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import { clearDraft } from '~/lib/utils/autosave';

export default {
  name: 'ImageDiffViewerWithDiscussions',
  components: {
    NoteForm,
    BaseImageDiffOverlay,
    DiffDiscussions,
    DraftNote,
    ImageViewer,
  },
  inject: {
    store: { type: Object },
    userPermissions: {
      type: Object,
    },
  },
  props: {
    imageData: {
      type: Object,
      required: true,
    },
    oldPath: {
      type: String,
      required: false,
      default: null,
    },
    newPath: {
      type: String,
      required: false,
      default: null,
    },
    diffRefs: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      commentForm: null,
    };
  },
  computed: {
    canStartReview() {
      return Boolean(this.store.createDraftImageDiscussion);
    },
    autosaveKey() {
      return `${window.location.pathname}-image-${[this.oldPath || '-', this.newPath || '-'].join('-')}`;
    },
    discussions() {
      return this.store.findAllImageDiscussionsForFile({
        oldPath: this.oldPath,
        newPath: this.newPath,
        diffRefs: this.diffRefs,
      });
    },
    publishedDiscussions() {
      return this.discussions.filter((discussion) => !discussion.isDraft);
    },
    drafts() {
      return this.discussions.filter((discussion) => discussion.isDraft);
    },
  },
  methods: {
    openForm(data) {
      this.commentForm = { noteBody: this.commentForm ? this.commentForm.noteBody : '', ...data };
    },
    commentPosition() {
      return {
        ...this.diffRefs,
        old_path: this.oldPath,
        new_path: this.newPath,
        position_type: 'image',
        width: this.commentForm.width,
        height: this.commentForm.height,
        x: this.commentForm.x,
        y: this.commentForm.y,
      };
    },
    closeForm() {
      clearDraft(this.autosaveKey);
      this.commentForm = null;
    },
    async saveNote(noteBody) {
      await this.store.createImageDiscussion({ position: this.commentPosition(), noteBody });
      this.closeForm();
    },
    async saveDraft(noteBody) {
      await this.store.createDraftImageDiscussion({ position: this.commentPosition(), noteBody });
      this.closeForm();
    },
  },
};
</script>

<template>
  <div class="rd-image-with-discussions">
    <image-viewer :image-data="imageData">
      <template #image-overlay="{ width, height, renderedWidth, renderedHeight }">
        <base-image-diff-overlay
          v-if="renderedWidth"
          :width="width"
          :height="height"
          :rendered-width="renderedWidth"
          :rendered-height="renderedHeight"
          :discussions="discussions"
          :can-comment="userPermissions.can_create_note"
          :comment-form="commentForm"
          @image-click="openForm"
        />
      </template>
    </image-viewer>
    <diff-discussions :discussions="publishedDiscussions" counter-badge-visible />
    <draft-note v-for="discussion in drafts" :key="discussion.id" :draft="discussion.draft" />
    <div v-if="commentForm" class="gl-px-5 gl-py-4">
      <note-form
        :autosave-key="autosaveKey"
        autofocus
        :note-body="commentForm.noteBody"
        :save-note="saveNote"
        :save-draft="canStartReview ? saveDraft : null"
        :has-drafts="Boolean(store.hasDrafts)"
        :save-button-title="__('Comment')"
        restore-from-autosave
        @input="commentForm.noteBody = $event"
        @cancel="commentForm = null"
      />
    </div>
  </div>
</template>
