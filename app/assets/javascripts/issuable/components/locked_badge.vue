<script>
import { GlBadge, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { issuableTypeText } from '~/issues/constants';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlBadge,
    GlIcon,
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
  <gl-badge v-gl-tooltip :title="title" variant="warning" data-testid="locked-badge">
    <gl-icon name="lock" />
    <span class="gl-sr-only">{{ __('Locked') }}</span>
  </gl-badge>
</template>
