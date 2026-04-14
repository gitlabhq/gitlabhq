<script>
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
