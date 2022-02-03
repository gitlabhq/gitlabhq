<script>
import { mapGetters } from 'vuex';
import imageDiff from '~/diffs/mixins/image_diff';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import DraftNote from './draft_note.vue';

export default {
  components: {
    DraftNote,
    DesignNotePin,
  },
  mixins: [imageDiff],
  props: {
    fileHash: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters('batchComments', ['draftsForFile']),
    drafts() {
      return this.draftsForFile(this.fileHash);
    },
  },
};
</script>

<template>
  <div>
    <div
      v-for="(draft, index) in drafts"
      :key="draft.id"
      class="discussion-notes diff-discussions position-relative"
    >
      <div class="notes">
        <design-note-pin
          :label="toggleText(draft, index)"
          is-draft
          class="js-diff-notes-index gl-translate-x-n50"
          size="sm"
        />
        <draft-note :draft="draft" />
      </div>
    </div>
  </div>
</template>
