<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    buttonLabel: s__('MergeRequests|Create issue to resolve thread'),
  },
  name: 'ResolveWithIssueButton',
  components: {
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
  <gl-button
    v-gl-tooltip
    :href="url"
    :title="$options.i18n.buttonLabel"
    :aria-label="$options.i18n.buttonLabel"
    class="new-issue-for-discussion discussion-create-issue-btn gl-w-full @sm/panel:gl-w-auto"
    icon="work-item-new"
  />
</template>
