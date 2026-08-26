<script>
import {
  keysFor,
  MR_NEXT_UNRESOLVED_DISCUSSION,
  MR_PREVIOUS_UNRESOLVED_DISCUSSION,
} from '~/behaviors/shortcuts/keybindings';
import { Mousetrap } from '~/lib/mousetrap';
import eventHub from '~/notes/event_hub';
import discussionNavigation from '~/notes/mixins/discussion_navigation';
import { getSlotFunction, normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

export default normalizeRender({
  mixins: [discussionNavigation],
  created() {
    eventHub.$on('jump-to-first-unresolved-discussion', this.jumpToFirstUnresolvedDiscussion);
  },
  mounted() {
    Mousetrap.bind(keysFor(MR_NEXT_UNRESOLVED_DISCUSSION), this.jumpToNextDiscussion);
    Mousetrap.bind(keysFor(MR_PREVIOUS_UNRESOLVED_DISCUSSION), this.jumpToPreviousDiscussion);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(MR_NEXT_UNRESOLVED_DISCUSSION));
    Mousetrap.unbind(keysFor(MR_PREVIOUS_UNRESOLVED_DISCUSSION));

    eventHub.$off('jump-to-first-unresolved-discussion', this.jumpToFirstUnresolvedDiscussion);
  },
  render() {
    return getSlotFunction(this)?.();
  },
});
</script>
