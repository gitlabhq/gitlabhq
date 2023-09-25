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
      return sprintf(__('This %{issuable} is hidden because its author has been banned.'), {
        issuable: issuableTypeText[this.issuableType],
      });
    },
  },
};
</script>

<template>
  <gl-badge v-gl-tooltip :title="title" variant="warning">
    <gl-icon name="spam" />
    <span class="gl-sr-only">{{ __('Hidden') }}</span>
  </gl-badge>
</template>
