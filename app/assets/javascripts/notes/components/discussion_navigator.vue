<script>
import { throttle } from 'lodash';
import {
  keysFor,
  MR_NEXT_UNRESOLVED_DISCUSSION,
  MR_PREVIOUS_UNRESOLVED_DISCUSSION,
} from '~/behaviors/shortcuts/keybindings';
import { Mousetrap } from '~/lib/mousetrap';
import eventHub from '~/notes/event_hub';
import discussionNavigation from '~/notes/mixins/discussion_navigation';

export default {
  mixins: [discussionNavigation],
  data() {
    return {
      jumpToNext: throttle(() => this.jumpToNextDiscussion({ behavior: 'auto' }), 200),
      jumpToPrevious: throttle(() => this.jumpToPreviousDiscussion({ behavior: 'auto' }), 200),
    };
  },
  created() {
    eventHub.$on('jumpToFirstUnresolvedDiscussion', this.jumpToFirstUnresolvedDiscussion);
  },
  mounted() {
    Mousetrap.bind(keysFor(MR_NEXT_UNRESOLVED_DISCUSSION), this.jumpToNext);
    Mousetrap.bind(keysFor(MR_PREVIOUS_UNRESOLVED_DISCUSSION), this.jumpToPrevious);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(MR_NEXT_UNRESOLVED_DISCUSSION));
    Mousetrap.unbind(keysFor(MR_PREVIOUS_UNRESOLVED_DISCUSSION));

    eventHub.$off('jumpToFirstUnresolvedDiscussion', this.jumpToFirstUnresolvedDiscussion);
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
