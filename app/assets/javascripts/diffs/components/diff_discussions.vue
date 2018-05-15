<script>
import noteableDiscussion from '../../notes/components/noteable_discussion.vue';

export default {
  components: {
    noteableDiscussion,
  },
  props: {
    notes: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div
    v-if="notes.length"
  >
    <div
      v-for="notesArr in notes"
      :key="notesArr.id"
      class="discussion-notes diff-discussions"
    >
      <ul class="notes" :data-discussion-id="notesArr.id">
        <noteable-discussion
          :note="notesArr"
          :render-header="false"
          :render-diff-file="false"
          :always-expanded="true"
        />
      </ul>
    </div>
  </div>
</template>
