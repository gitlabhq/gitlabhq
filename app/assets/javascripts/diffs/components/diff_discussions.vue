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
  <div>
    <div
      v-for="discussion in discussions"
      :key="discussion.id"
      class="discussion-notes diff-discussions"
    >
      <ul
        :data-discussion-id="discussion.id"
        class="notes"
      >
        <noteable-discussion
          :discussion="discussion"
          :render-header="false"
          :render-diff-file="false"
          :always-expanded="true"
          :discussions-by-diff-order="true"
        />
      </ul>
    </div>
  </div>
</template>
