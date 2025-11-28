<script>
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import NoteableNote from './noteable_note.vue';

export default {
  name: 'DiscussionNotes',
  components: {
    // System note is not migrated yet since we don't need it
    // Refactor this to static import once the component is migrated
    SystemNote: () => import('~/vue_shared/components/notes/system_note.vue'),
    NoteableNote,
    ToggleRepliesWidget,
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
  <ul class="gl-list-none gl-p-0">
    <system-note v-if="firstNote.system" :note="firstNote" />
    <noteable-note
      v-else
      :note="firstNote"
      :show-reply-button="userPermissions.can_create_note"
      @noteDeleted="$emit('noteDeleted', firstNote)"
      @noteUpdated="$emit('noteUpdated', $event)"
      @noteEdited="$emit('noteEdited', { note: firstNote, value: $event })"
      @startReplying="$emit('startReplying')"
      @startEditing="$emit('startEditing', firstNote)"
      @cancelEditing="$emit('cancelEditing', firstNote)"
      @toggleAward="$emit('toggleAward', { note: firstNote, award: $event })"
    >
      <template #avatar-badge>
        <slot name="avatar-badge"></slot>
      </template>
    </noteable-note>
    <li
      v-if="hasReplies || userPermissions.can_create_note"
      class="gl-m-0 gl-rounded-[var(--content-border-radius)] gl-bg-subtle"
    >
      <ul class="gl-list-none gl-p-0">
        <toggle-replies-widget
          v-if="hasReplies"
          :collapsed="!expanded"
          :replies="replies"
          class="gl-border-t !gl-border-x-0 gl-border-t-subtle"
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
              @noteUpdated="$emit('noteUpdated', $event)"
              @noteEdited="$emit('noteEdited', { note, value: $event })"
              @startEditing="$emit('startEditing', note)"
              @cancelEditing="$emit('cancelEditing', note)"
              @toggleAward="$emit('toggleAward', { note, award: $event })"
            >
              <template #avatar-badge>
                <slot name="avatar-badge"></slot>
              </template>
            </noteable-note>
          </template>
          <slot name="footer" :has-replies="hasReplies"></slot>
        </template>
      </ul>
    </li>
  </ul>
</template>
