<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import discussionNavigation from '../mixins/discussion_navigation';

export default {
  name: 'JumpToNextDiscussionButton',
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [discussionNavigation],
  props: {
    fromDiscussionId: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="btn-group" role="group">
    <button
      ref="button"
      v-gl-tooltip
      class="btn btn-default discussion-next-btn"
      :title="s__('MergeRequests|Jump to next unresolved thread')"
      data-track-event="click_button"
      data-track-label="mr_next_unresolved_thread"
      data-track-property="click_next_unresolved_thread"
      @click="jumpToNextRelativeDiscussion(fromDiscussionId)"
    >
      <gl-icon name="comment-next" />
    </button>
  </div>
</template>
