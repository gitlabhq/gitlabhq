<script>
import { GlIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import NoteHeader from '~/notes/components/note_header.vue';

export default {
  components: {
    NoteHeader,
    GlIcon,
  },
  directives: {
    SafeHtml,
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
    noteAuthor() {
      const {
        author,
        author: { id },
      } = this.note;
      return { ...author, id: id?.split('/').pop() };
    },
  },
};
</script>

<template>
  <li
    :id="noteAnchorId"
    class="timeline-entry note system-note note-wrapper !gl-p-0"
    data-testid="alert-system-note-container"
  >
    <div class="gl-relative gl-inline-flex gl-items-center">
      <div
        class="gl-box-sizing-content-box -gl-mt-2 gl-mr-6 gl-inline gl-rounded-full gl-border-1 gl-border-solid gl-border-default gl-bg-default gl-p-3"
      >
        <gl-icon :name="note.systemNoteIconName" variant="subtle" />
      </div>

      <div class="note-header">
        <note-header :author="noteAuthor" :created-at="note.createdAt" :note-id="note.id">
          <span v-safe-html="note.bodyHtml"></span>
        </note-header>
      </div>
    </div>
  </li>
</template>
