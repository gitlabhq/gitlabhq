<script>
import { GlTooltipDirective } from '@gitlab/ui';
import Tracking from '~/tracking';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  methods: {
    handleClick() {
      this.$emit('setAddColumnFormVisibility', true);
      this.track('click_button', { label: 'create_list' });
    },
  },
};
</script>

<template>
  <button
    v-gl-tooltip="{ placement: 'top', boundary: 'window' }"
    data-testid="board-add-new-column-between-button"
    :title="__('New list')"
    :aria-label="__('New list')"
    class="gl-h-full gl-w-5 gl-border-none gl-bg-transparent gl-p-0 gl-opacity-0 hover:gl-opacity-10 focus:gl-opacity-10 focus:gl-outline-none"
    @click="handleClick"
  >
    <div class="gl-flex gl-h-full gl-w-full gl-justify-center">
      <div class="gl-border gl-h-full gl-w-0 gl-border-blue-500"></div>
    </div>
  </button>
</template>
