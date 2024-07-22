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
      return sprintf(__('This %{issuable} is hidden because its author has been banned.'), {
        issuable: issuableTypeText[this.issuableType],
      });
    },
  },
};
</script>

<template>
  <gl-badge
    v-gl-tooltip
    icon="spam"
    :title="title"
    :aria-label="__('Hidden')"
    variant="warning"
    class="gl-shrink-0"
  />
</template>
