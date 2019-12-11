<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'ResolveWithIssueButton',
  components: {
    Icon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    url: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="btn-group" role="group">
    <gl-button
      v-gl-tooltip
      :href="url"
      :title="s__('MergeRequests|Resolve this thread in a new issue')"
      class="new-issue-for-discussion discussion-create-issue-btn"
    >
      <icon name="issue-new" />
    </gl-button>
  </div>
</template>
