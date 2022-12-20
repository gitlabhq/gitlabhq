<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { i18n } from '../constants';

export default {
  i18n,
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <ul class="gl-display-contents">
    <li
      v-if="issue.mergeRequestsCount"
      v-gl-tooltip
      class="gl-display-none gl-sm-display-block gl-mr-3"
      :title="$options.i18n.relatedMergeRequests"
      data-testid="merge-requests"
    >
      <gl-icon name="merge-request" />
      {{ issue.mergeRequestsCount }}
    </li>
    <li
      v-if="issue.upvotes"
      v-gl-tooltip
      class="gl-display-none gl-sm-display-block gl-mr-3"
      :title="$options.i18n.upvotes"
      data-testid="issuable-upvotes"
    >
      <gl-icon name="thumb-up" />
      {{ issue.upvotes }}
    </li>
    <li
      v-if="issue.downvotes"
      v-gl-tooltip
      class="gl-display-none gl-sm-display-block gl-mr-3"
      :title="$options.i18n.downvotes"
      data-testid="issuable-downvotes"
    >
      <gl-icon name="thumb-down" />
      {{ issue.downvotes }}
    </li>
    <slot></slot>
  </ul>
</template>
