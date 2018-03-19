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
  <div>
    <div
      v-for="notesArr in notes"
      :key="notesArr.id"
      class="discussion-notes diff-discussions"
    >
      <ul class="notes">
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
