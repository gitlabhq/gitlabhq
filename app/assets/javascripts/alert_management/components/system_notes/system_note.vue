<script>
import NoteHeader from '~/notes/components/note_header.vue';
import { spriteIcon } from '~/lib/utils/common_utils';

export default {
  components: {
    NoteHeader,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  computed: {
    noteAnchorId() {
      return `note_${this.note?.id?.split('/').pop()}`;
    },
    iconHtml() {
      return spriteIcon('user');
    },
  },
};
</script>

<template>
  <li :id="noteAnchorId" class="timeline-entry note system-note note-wrapper">
    <div class="timeline-entry-inner">
      <div class="timeline-icon" v-html="iconHtml"></div>
      <div class="timeline-content">
        <div class="note-header">
          <note-header :author="note.author" :created-at="note.createdAt" :note-id="note.id">
            <span v-html="note.bodyHtml"></span>
          </note-header>
        </div>
      </div>
    </div>
  </li>
</template>
