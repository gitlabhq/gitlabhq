<script>
import { mapState } from 'pinia';
import imageDiff from '~/diffs/mixins/image_diff';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import { useBatchComments } from '~/batch_comments/store';
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
    showPin: {
      type: Boolean,
      required: false,
      default: true,
    },
    positionType: {
      type: String,
      required: false,
      default: '',
    },
    autosaveKey: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState(useBatchComments, ['draftsForFile']),
    drafts() {
      return this.draftsForFile(this.fileHash).filter(
        (f) => f.position?.position_type === this.positionType,
      );
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
          v-if="showPin"
          :label="toggleText(draft, index)"
          is-draft
          class="js-diff-notes-index -gl-translate-x-1/2"
          size="sm"
        />
        <draft-note :draft="draft" :autosave-key="autosaveKey" />
      </div>
    </div>
  </div>
</template>
