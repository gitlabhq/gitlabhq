<script>
/* global Mousetrap */
import 'mousetrap';
import discussionNavigation from '~/notes/mixins/discussion_navigation';

export default {
  mixins: [discussionNavigation],
  mounted() {
    Mousetrap.bind('n', this.jumpToNextDiscussion);
    Mousetrap.bind('p', this.jumpToPreviousDiscussion);
  },
  beforeDestroy() {
    Mousetrap.unbind('n');
    Mousetrap.unbind('p');
  },
  render() {
    return this.$slots.default;
  },
};
</script>
