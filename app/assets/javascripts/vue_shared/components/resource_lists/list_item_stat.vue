<script>
import { GlIcon, GlTooltipDirective, GlLink } from '@gitlab/ui';

export default {
  components: { GlIcon },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tooltipText: {
      type: String,
      required: false,
      default: null,
    },
    iconName: {
      type: String,
      required: true,
    },
    stat: {
      type: [String, Number],
      required: true,
    },
    href: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    component() {
      return this.href ? GlLink : 'div';
    },
  },
};
</script>

<template>
  <component
    :is="component"
    v-gl-tooltip="tooltipText"
    :aria-label="tooltipText"
    :href="href"
    class="gl-flex gl-items-center gl-gap-x-2 gl-text-subtle"
  >
    <gl-icon :name="iconName" />
    <span class="gl-leading-1">{{ stat }}</span>
  </component>
</template>
