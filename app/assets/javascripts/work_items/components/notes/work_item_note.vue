<script>
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import NoteBody from './work_item_note_body.vue';

export default {
  components: {
    NoteHeader,
    NoteBody,
    TimelineEntryItem,
    GlAvatarLink,
    GlAvatar,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  computed: {
    author() {
      return this.note.author;
    },
    noteAnchorId() {
      return `note_${this.note.id}`;
    },
  },
};
</script>

<template>
  <timeline-entry-item
    :id="noteAnchorId"
    :class="{ 'internal-note': note.internal }"
    :data-note-id="note.id"
    class="note note-wrapper note-comment"
  >
    <div class="timeline-avatar gl-float-left">
      <gl-avatar-link :href="author.webUrl">
        <gl-avatar
          :src="author.avatarUrl"
          :entity-name="author.username"
          :alt="author.name"
          :size="32"
        />
      </gl-avatar-link>
    </div>

    <div class="timeline-content">
      <div class="note-header">
        <note-header :author="author" :created-at="note.createdAt" :note-id="note.id" />
      </div>
      <div class="timeline-discussion-body">
        <note-body :note="note" />
      </div>
    </div>
  </timeline-entry-item>
</template>
