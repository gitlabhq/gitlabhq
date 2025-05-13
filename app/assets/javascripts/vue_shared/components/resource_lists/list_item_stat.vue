<script>
import { GlIcon, GlLink, GlTooltip } from '@gitlab/ui';

export default {
  components: { GlIcon, GlTooltip },
  props: {
    tooltipText: {
      type: String,
      required: false,
      default: null,
    },
    a11yText: {
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
    tooltipTargetEl() {
      return this.href ? this.$refs?.stat?.$el : this.$refs?.stat;
    },
  },
  methods: {
    onTooltipShown() {
      this.$emit('hover');
    },
    onClick() {
      if (!this.href) {
        return;
      }

      this.$emit('click');
    },
  },
};
</script>

<template>
  <component
    :is="component"
    ref="stat"
    :aria-label="a11yText || tooltipText"
    :href="href"
    class="gl-flex gl-items-center gl-gap-x-2 gl-text-subtle"
    @click="onClick"
  >
    <gl-icon :name="iconName" />
    <span class="gl-leading-1">{{ stat }}</span>
    <gl-tooltip :target="() => tooltipTargetEl" @shown="onTooltipShown">{{
      tooltipText
    }}</gl-tooltip>
  </component>
</template>
