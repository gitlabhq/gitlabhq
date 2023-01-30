<script>
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import NoteBody from '~/work_items/components/notes/work_item_note_body.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import NoteActions from '~/work_items/components/notes/work_item_note_actions.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

export default {
  name: 'WorkItemNoteThread',
  components: {
    TimelineEntryItem,
    NoteBody,
    NoteHeader,
    NoteActions,
    GlAvatar,
    GlAvatarLink,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
    isFirstNote: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    author() {
      return this.note.author;
    },
    entryClass() {
      return {
        'note note-wrapper note-comment': true,
        'gl-p-4': !this.isFirstNote,
      };
    },
    showReply() {
      return this.note.userPermissions.createNote && this.isFirstNote;
    },
  },
  methods: {
    renderGFM() {
      renderGFM(this.$refs['note-body']);
    },
    showReplyForm() {
      this.$emit('startReplying');
    },
  },
};
</script>

<template>
  <timeline-entry-item :class="entryClass">
    <div v-if="!isFirstNote" :key="note.id" class="timeline-avatar gl-float-left">
      <gl-avatar-link :href="author.webUrl">
        <gl-avatar
          :src="author.avatarUrl"
          :entity-name="author.username"
          :alt="author.name"
          :size="32"
        />
      </gl-avatar-link>
    </div>
    <div class="timeline-content-inner">
      <div class="note-header">
        <note-header :author="author" :created-at="note.createdAt" :note-id="note.id" />
        <note-actions :show-reply="showReply" @startReplying="showReplyForm" />
      </div>
      <div class="timeline-discussion-body">
        <note-body ref="noteBody" :note="note" />
      </div>
    </div>
  </timeline-entry-item>
</template>
