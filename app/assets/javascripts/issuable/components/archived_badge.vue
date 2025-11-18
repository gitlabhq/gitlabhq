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
      return sprintf(__('This %{issuable} belongs to an archived project and is read-only.'), {
        issuable: issuableTypeText[this.issuableType] || this.issuableType || 'item',
      });
    },
  },
};
</script>

<template>
  <gl-badge v-gl-tooltip :title="title" :aria-label="title" variant="info" class="gl-shrink-0">
    {{ __('Archived') }}
  </gl-badge>
</template>
