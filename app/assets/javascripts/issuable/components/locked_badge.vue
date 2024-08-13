<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { issuableTypeText } from '~/issues/constants';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    issuableType: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    title() {
      return sprintf(
        __('The discussion in this %{issuable} is locked. Only project members can comment.'),
        {
          issuable: issuableTypeText[this.issuableType],
        },
      );
    },
  },
};
</script>

<template>
  <gl-badge
    v-gl-tooltip
    icon="lock"
    :title="title"
    :aria-label="title"
    variant="warning"
    data-testid="locked-badge"
    class="gl-shrink-0"
  />
</template>
