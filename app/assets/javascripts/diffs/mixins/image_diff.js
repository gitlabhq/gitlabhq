// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';

export default {
  methods: {
    ...mapActions(['toggleDiscussion']),
    clickedToggle(discussion) {
      this.toggleDiscussion({ discussionId: discussion.id });
    },
    toggleText(discussion, index) {
      return index + 1;
    },
  },
};
