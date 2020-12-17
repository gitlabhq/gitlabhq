<script>
import { GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'MemberSource',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    memberSource: {
      type: Object,
      required: true,
    },
    isDirectMember: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <span v-if="isDirectMember">{{ __('Direct member') }}</span>
  <a v-else v-gl-tooltip.hover :title="__('Inherited')" :href="memberSource.webUrl">{{
    memberSource.name
  }}</a>
</template>
