<script>
import noteableNote from '~/notes/components/noteable_note.vue';
import discussionReply from '~/notes/components/discussion_reply.vue';

export default {
  components: {
    discussionReply,
    noteableNote,
  },
  props: {
    notes: {
      type: Array,
      required: true,
    },
  },
  methods: {
    componentData(note) {
      return note.isPlaceholderNote ? this.note.notes[0] : note;
    },
  },
};
</script>

<template>
  <div
    v-if="notes.length"
  >
    <div
      v-for="discussion in notes"
      :key="discussion.id"
      class="discussion-notes diff-discussions"
    >
      <ul
        class="notes"
        :data-discussion-id="discussion.id"
      >
        <noteable-note
          v-for="note in discussion.notes"
          :note="componentData(note)"
          :key="note.id"
        />
      </ul>
      <discussion-reply
        :note="discussion"
      />
    </div>
  </div>
</template>
