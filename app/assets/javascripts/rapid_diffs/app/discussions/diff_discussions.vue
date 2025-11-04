<script>
import { mapActions } from 'pinia';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import NoteableDiscussion from './noteable_discussion.vue';

export default {
  name: 'DiffDiscussions',
  components: {
    NoteableDiscussion,
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
  },
  methods: {
    ...mapActions(useDiffDiscussions, [
      'saveNote',
      'expandDiscussionReplies',
      'toggleDiscussionReplies',
    ]),
  },
};
</script>

<template>
  <div>
    <div
      v-for="discussion in discussions"
      :key="discussion.id"
      class="discussion-notes diff-discussions !gl-relative"
    >
      <ul class="notes">
        <noteable-discussion
          :discussion="discussion"
          :save-note="saveNote"
          @showReplyForm="expandDiscussionReplies(discussion)"
          @toggleDiscussionReplies="toggleDiscussionReplies(discussion)"
        />
      </ul>
    </div>
  </div>
</template>
