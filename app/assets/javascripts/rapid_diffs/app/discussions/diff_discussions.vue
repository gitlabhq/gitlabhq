<script>
import { scrollPastCoveringElements } from '~/lib/utils/sticky';
import { getNoteIdFromHash } from '~/notes/utils/note_hash';
import { hasScrolled, markAsScrolled } from '~/rapid_diffs/utils/scroll_to_linked_fragment';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import NoteableDiscussion from './noteable_discussion.vue';

export default {
  name: 'DiffDiscussions',
  components: {
    DesignNotePin,
    NoteableDiscussion,
  },
  inject: {
    store: { type: Object },
    linkedFileData: { default: null },
    filePaths: { default: null },
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
    timelineLayout: {
      type: Boolean,
      required: false,
      default: false,
    },
    counterBadgeVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  mounted() {
    this.scrollToNoteFragment();
  },
  methods: {
    scrollToNoteFragment() {
      if (hasScrolled() || !this.linkedFileData || !this.filePaths) return;
      if (
        this.linkedFileData.old_path !== this.filePaths.oldPath ||
        this.linkedFileData.new_path !== this.filePaths.newPath
      )
        return;
      const noteId = getNoteIdFromHash();
      if (!noteId) return;
      const noteElement = document.getElementById(`note_${noteId}`);
      if (!noteElement) return;
      // Clear the hash first so the click registers as a change,
      // re-triggering :target evaluation for client-rendered notes
      window.history.replaceState(null, '', window.location.pathname + window.location.search);
      noteElement.querySelector(`a[href$="#note_${noteId}"]`)?.click();
      noteElement.scrollIntoView({ block: 'start' });
      scrollPastCoveringElements(noteElement);
      markAsScrolled();
    },
  },
};
</script>

<template>
  <div class="gl-rounded-[var(--content-border-radius)] gl-bg-default gl-text-default">
    <ul class="gl-m-0 gl-list-none gl-p-0">
      <noteable-discussion
        v-for="(discussion, index) in discussions"
        :key="discussion.id"
        :class="{
          'gl-mt-4': timelineLayout && index !== 0,
          'gl-border-t': !timelineLayout && index !== 0,
        }"
        :discussion="discussion"
        :request-last-note-editing="store.requestLastNoteEditing"
        :toggle-resolve-note="store.toggleResolveNote"
        :timeline-layout="timelineLayout"
        :is-last-discussion="index === discussions.length - 1"
        @toggleDiscussionReplies="store.toggleDiscussionReplies(discussion)"
        @noteEdited="store.editNote"
        @startEditing="store.setEditingMode($event, true)"
        @cancelEditing="store.setEditingMode($event, false)"
        @startReplying="store.startReplying(discussion)"
        @stopReplying="store.stopReplying(discussion)"
      >
        <template v-if="counterBadgeVisible" #avatar-badge>
          <design-note-pin
            class="gl-absolute gl-mt-5"
            :label="index + 1"
            size="sm"
            :clickable="false"
          />
        </template>
      </noteable-discussion>
    </ul>
  </div>
</template>
