<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    confidential: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    confidentialIcon() {
      return this.confidential ? 'eye-slash' : 'eye';
    },
    tooltipLabel() {
      return this.confidential ? __('Confidential') : __('Not confidential');
    },
  },
};
</script>

<template>
  <div>
    <div
      v-gl-tooltip.viewport.left
      :title="tooltipLabel"
      class="sidebar-collapsed-icon"
      data-testid="sidebar-collapsed-icon"
      @click="$emit('expandSidebar')"
    >
      <gl-icon
        :size="16"
        :name="confidentialIcon"
        class="sidebar-item-icon gl-inline-block"
        :class="{ 'is-active': confidential }"
      />
    </div>
    <gl-icon
      :size="16"
      :name="confidentialIcon"
      class="sidebar-item-icon hide-collapsed gl-inline-block"
      :class="{ 'is-active': confidential }"
    />
    <span class="hide-collapsed" data-testid="confidential-text">
      {{ tooltipLabel }}
    </span>
  </div>
</template>
