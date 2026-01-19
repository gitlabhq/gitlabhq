<script>
import ImageViewer from '~/rapid_diffs/app/image_viewer/image_viewer.vue';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import BaseImageDiffOverlay from '~/diffs/components/base_image_diff_overlay.vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import axios from '~/lib/utils/axios_utils';
import { clearDraft } from '~/lib/utils/autosave';
import { createAlert } from '~/alert';
import { __ } from '~/locale';

export default {
  name: 'ImageDiffViewerWithDiscussions',
  components: {
    NoteForm,
    BaseImageDiffOverlay,
    DiffDiscussions,
    ImageViewer,
  },
  inject: {
    userPermissions: {
      type: Object,
    },
    endpoints: {
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
  },
  data() {
    return {
      commentForm: null,
    };
  },
  computed: {
    autosaveKey() {
      return `${window.location.pathname}-image-${[this.oldPath || '-', this.newPath || '-'].join('-')}`;
    },
    discussions() {
      return useDiffDiscussions().getImageDiscussions(this.oldPath, this.newPath);
    },
  },
  methods: {
    openForm(data) {
      this.commentForm = { noteBody: this.commentForm ? this.commentForm.noteBody : '', ...data };
    },
    async saveNote(noteBody) {
      try {
        const {
          data: { discussion },
        } = await axios.post(this.endpoints.discussions, {
          note: {
            position: {
              old_path: this.oldPath,
              new_path: this.newPath,
              position_type: 'image',
              width: this.commentForm.width,
              height: this.commentForm.height,
              x: this.commentForm.x,
              y: this.commentForm.y,
            },
            note: noteBody,
          },
        });
        clearDraft(this.autosaveKey);
        useDiffDiscussions().addDiscussion(discussion);
        this.commentForm = null;
      } catch (error) {
        createAlert({
          message: __('Failed to submit your comment. Please try again.'),
          parent: this.$refs.formRoot,
          error,
        });
      }
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
    <diff-discussions :discussions="discussions" counter-badge-visible />
    <div v-if="commentForm" ref="formRoot" class="gl-px-5 gl-py-4">
      <note-form
        :autosave-key="autosaveKey"
        autofocus
        :note-body="commentForm.noteBody"
        :save-note="saveNote"
        :save-button-title="__('Comment')"
        restore-from-autosave
        @input="commentForm.noteBody = $event"
        @cancel="commentForm = null"
      />
    </div>
  </div>
</template>
