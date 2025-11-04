<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: { GlButton },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['isIconOnly'],
  computed: {
    icon() {
      return this.isIconOnly ? 'collapse-right' : 'collapse-left';
    },
    text() {
      return this.isIconOnly
        ? s__('Navigation|Expand sidebar')
        : s__('Navigation|Collapse sidebar');
    },
  },
  methods: {
    emitToggle() {
      this.$emit('toggle');
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.right="isIconOnly ? text : ''"
    :class="[
      'super-sidebar-nav-item !gl-mx-3 !-gl-mt-2 !gl-mb-2 !gl-justify-start !gl-px-[0.375rem] !gl-py-2 gl-font-semibold',
      { 'gl-gap-3': !isIconOnly },
    ]"
    :button-text-classes="isIconOnly ? 'gl-hidden' : null"
    :icon="icon"
    :aria-label="text"
    category="tertiary"
    data-testid="super-sidebar-collapse-button"
    @click="emitToggle"
    >{{ text }}</gl-button
  >
</template>
