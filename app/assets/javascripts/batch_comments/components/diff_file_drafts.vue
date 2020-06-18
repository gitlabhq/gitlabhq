<script>
import { mapGetters } from 'vuex';
import imageDiff from '~/diffs/mixins/image_diff';
import DraftNote from './draft_note.vue';

export default {
  components: {
    DraftNote,
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
        <span class="d-block btn-transparent badge badge-pill is-draft js-diff-notes-index">
          {{ toggleText(draft, index) }}
        </span>
        <draft-note :draft="draft" />
      </div>
    </div>
  </div>
</template>
