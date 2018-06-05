<script>
import noteableDiscussion from '../../notes/components/noteable_discussion.vue';

export default {
  components: {
    noteableDiscussion,
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div
    v-if="discussions.length"
  >
    <div
      v-for="discussion in discussions"
      :key="discussion.id"
      class="discussion-notes diff-discussions"
    >
      <ul
        class="notes"
        :data-discussion-id="discussion.id"
      >
        <noteable-discussion
          :discussion="discussion"
          :render-header="false"
          :render-diff-file="false"
          :always-expanded="true"
        />
      </ul>
    </div>
  </div>
</template>
