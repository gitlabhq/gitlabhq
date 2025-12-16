<script>
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import NewLineDiscussionForm from './new_line_discussion_form.vue';
import DiffDiscussions from './diff_discussions.vue';

export default {
  name: 'DiffLineDiscussions',
  components: {
    NewLineDiscussionForm,
    DiffDiscussions,
  },
  props: {
    position: {
      type: Object,
      required: true,
    },
  },
  computed: {
    discussions() {
      return useDiffDiscussions()
        .findDiscussionsForPosition(this.position)
        .filter((discussion) => !discussion.hidden);
    },
  },
};
</script>

<template>
  <div v-if="discussions.length">
    <div
      v-for="(discussion, index) in discussions"
      :key="index"
      :class="{ 'gl-border-t': index > 0 }"
    >
      <new-line-discussion-form v-if="discussion.isForm" :discussion="discussion" />
      <!-- eslint-disable-next-line @gitlab/vue-no-new-non-primitive-in-template -->
      <diff-discussions v-else :discussions="[discussion]" />
    </div>
  </div>
</template>
