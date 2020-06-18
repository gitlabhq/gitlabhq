<script>
import DraftNote from './draft_note.vue';

export default {
  components: {
    DraftNote,
  },
  props: {
    draft: {
      type: Object,
      required: true,
    },
    diffFile: {
      type: Object,
      required: true,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <tr class="notes_holder js-temp-notes-holder">
    <td class="notes-content" colspan="4">
      <div class="content"><draft-note :draft="draft" :diff-file="diffFile" :line="line" /></div>
    </td>
  </tr>
</template>
