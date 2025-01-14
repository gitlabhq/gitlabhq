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
    mergeRequest: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <ul class="gl-list-none gl-gap-3 gl-p-0">
    <li
      v-if="mergeRequest.upvotes"
      v-gl-tooltip
      :title="$options.i18n.upvotes"
      data-testid="issuable-upvotes"
    >
      <gl-icon name="thumb-up" />
      {{ mergeRequest.upvotes }}
    </li>
    <li
      v-if="mergeRequest.downvotes"
      v-gl-tooltip
      :title="$options.i18n.downvotes"
      data-testid="issuable-downvotes"
    >
      <gl-icon name="thumb-down" />
      {{ mergeRequest.downvotes }}
    </li>
  </ul>
</template>
