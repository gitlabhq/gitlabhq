<script>
import icon from '~/vue_shared/components/icon.vue';
import { GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'JumpToNextDiscussionButton',
  components: {
    icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <div class="btn-group" role="group">
    <button
      ref="button"
      v-gl-tooltip
      class="btn btn-default discussion-next-btn"
      :title="s__('MergeRequests|Jump to next unresolved discussion')"
      @click="$emit('onClick')"
    >
      <icon name="comment-next" />
    </button>
  </div>
</template>
