<script>
export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="note-body">
    <div
      v-html="note.note_html"
      class="note-text md"></div>
  </div>
</template>
