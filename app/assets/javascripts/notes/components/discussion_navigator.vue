<script>
/* global Mousetrap */
import 'mousetrap';
import {
  keysFor,
  MR_NEXT_UNRESOLVED_DISCUSSION,
  MR_PREVIOUS_UNRESOLVED_DISCUSSION,
} from '~/behaviors/shortcuts/keybindings';
import eventHub from '~/notes/event_hub';
import discussionNavigation from '~/notes/mixins/discussion_navigation';

export default {
  mixins: [discussionNavigation],
  created() {
    eventHub.$on('jumpToFirstUnresolvedDiscussion', this.jumpToFirstUnresolvedDiscussion);
  },
  mounted() {
    Mousetrap.bind(keysFor(MR_NEXT_UNRESOLVED_DISCUSSION), this.jumpToNextDiscussion);
    Mousetrap.bind(keysFor(MR_PREVIOUS_UNRESOLVED_DISCUSSION), this.jumpToPreviousDiscussion);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(MR_NEXT_UNRESOLVED_DISCUSSION));
    Mousetrap.unbind(keysFor(MR_PREVIOUS_UNRESOLVED_DISCUSSION));

    eventHub.$off('jumpToFirstUnresolvedDiscussion', this.jumpToFirstUnresolvedDiscussion);
  },
  render() {
    return this.$slots.default;
  },
};
</script>
