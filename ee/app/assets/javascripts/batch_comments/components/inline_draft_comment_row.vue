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
  },
};
</script>

<template>
  <tr
    class="notes_holder js-temp-notes-holder"
  >
    <td
      class="notes_content"
      colspan="3"
    >
      <div class="content">
        <draft-note
          :draft="draft"
        />
      </div>
    </td>
  </tr>
</template>
