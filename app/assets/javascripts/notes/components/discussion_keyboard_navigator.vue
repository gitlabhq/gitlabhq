<script>
/* global Mousetrap */
import 'mousetrap';
import discussionNavigation from '~/notes/mixins/discussion_navigation';
import eventHub from '~/notes/event_hub';

export default {
  mixins: [discussionNavigation],
  created() {
    eventHub.$on('jumpToFirstUnresolvedDiscussion', this.jumpToFirstUnresolvedDiscussion);
  },
  mounted() {
    Mousetrap.bind('n', this.jumpToNextDiscussion);
    Mousetrap.bind('p', this.jumpToPreviousDiscussion);
  },
  beforeDestroy() {
    Mousetrap.unbind('n');
    Mousetrap.unbind('p');

    eventHub.$off('jumpToFirstUnresolvedDiscussion', this.jumpToFirstUnresolvedDiscussion);
  },
  render() {
    return this.$slots.default;
  },
};
</script>
