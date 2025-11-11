<script>
import SystemNote from '~/vue_shared/components/notes/system_note.vue';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import DiscussionNotesRepliesWrapper from '~/notes/components/discussion_notes_replies_wrapper.vue';
import NoteableNote from '~/notes/components/noteable_note.vue';

export default {
  name: 'DiscussionNotes',
  components: {
    SystemNote,
    NoteableNote,
    ToggleRepliesWidget,
    DiscussionNotesRepliesWrapper,
  },
  inject: {
    userPermissions: {
      type: Object,
    },
  },
  props: {
    notes: {
      type: Array,
      required: true,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    hasReplies() {
      return Boolean(this.replies.length);
    },
    replies() {
      return this.notes.slice(1);
    },
    firstNote() {
      return this.notes[0];
    },
  },
};
</script>

<template>
  <div class="discussion-notes">
    <ul class="notes">
      <system-note v-if="firstNote.system" :note="firstNote" />
      <noteable-note
        v-else
        :note="firstNote"
        :show-reply-button="userPermissions.can_create_note"
        @startReplying="$emit('startReplying')"
        @noteDeleted="$emit('noteDeleted', firstNote)"
      >
        <template #avatar-badge>
          <slot name="avatar-badge"></slot>
        </template>
      </noteable-note>
      <discussion-notes-replies-wrapper
        v-if="hasReplies || userPermissions.can_create_note"
        is-diff-discussion
      >
        <toggle-replies-widget
          v-if="hasReplies"
          :collapsed="!expanded"
          :replies="replies"
          @toggle="$emit('toggleDiscussionReplies')"
        />
        <template v-if="expanded">
          <template v-for="note in replies">
            <system-note v-if="note.system" :key="`system-${note.id}`" :note="note" />
            <noteable-note
              v-else
              :key="note.id"
              :note="note"
              @noteDeleted="$emit('noteDeleted', note)"
            >
              <template #avatar-badge>
                <slot name="avatar-badge"></slot>
              </template>
            </noteable-note>
          </template>
        </template>
        <slot name="footer" :replies-visible="expanded || !hasReplies"></slot>
      </discussion-notes-replies-wrapper>
    </ul>
  </div>
</template>
