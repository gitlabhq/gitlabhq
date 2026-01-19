<script>
import { mapActions } from 'pinia';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import NoteableDiscussion from './noteable_discussion.vue';

export default {
  name: 'DiffDiscussions',
  components: {
    DesignNotePin,
    NoteableDiscussion,
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
  methods: {
    ...mapActions(useDiffDiscussions, [
      'replaceDiscussion',
      'updateNote',
      'deleteNote',
      'editNote',
      'setEditingMode',
      'toggleDiscussionReplies',
      'requestLastNoteEditing',
      'startReplying',
      'stopReplying',
      'toggleAward',
    ]),
  },
};
</script>

<template>
  <div class="gl-rounded-[var(--content-border-radius)] gl-bg-default gl-text-default">
    <ul class="gl-m-0 gl-list-none gl-p-0">
      <noteable-discussion
        v-for="(discussion, index) in discussions"
        :key="discussion.id"
        :class="timelineLayout && index !== 0 && 'gl-mt-4'"
        :discussion="discussion"
        :request-last-note-editing="requestLastNoteEditing"
        :timeline-layout="timelineLayout"
        :is-last-discussion="index === discussions.length - 1"
        @toggleDiscussionReplies="toggleDiscussionReplies(discussion)"
        @discussionUpdated="replaceDiscussion(discussion, $event)"
        @noteUpdated="updateNote"
        @noteDeleted="deleteNote"
        @noteEdited="editNote"
        @startEditing="setEditingMode($event, true)"
        @cancelEditing="setEditingMode($event, false)"
        @startReplying="startReplying(discussion)"
        @stopReplying="stopReplying(discussion)"
        @toggleAward="toggleAward"
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
