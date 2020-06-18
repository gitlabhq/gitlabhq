<script>
import { mapGetters } from 'vuex';
import DraftNote from './draft_note.vue';

export default {
  components: {
    DraftNote,
  },
  props: {
    line: {
      type: Object,
      required: true,
    },
    diffFileContentSha: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters('batchComments', ['draftForLine']),
    className() {
      return this.leftDraft > 0 || this.rightDraft > 0 ? '' : 'js-temp-notes-holder';
    },
    leftDraft() {
      return this.draftForLine(this.diffFileContentSha, this.line, 'left');
    },
    rightDraft() {
      return this.draftForLine(this.diffFileContentSha, this.line, 'right');
    },
  },
};
</script>

<template>
  <tr :class="className" class="notes_holder">
    <td class="notes_line old"></td>
    <td class="notes-content parallel old" colspan="2">
      <div v-if="leftDraft.isDraft" class="content"><draft-note :draft="leftDraft" /></div>
    </td>
    <td class="notes_line new"></td>
    <td class="notes-content parallel new" colspan="2">
      <div v-if="rightDraft.isDraft" class="content"><draft-note :draft="rightDraft" /></div>
    </td>
  </tr>
</template>
