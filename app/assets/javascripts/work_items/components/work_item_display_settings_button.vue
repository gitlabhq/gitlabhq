<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'WorkItemDisplaySettingsButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    selected: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['click'],
};
</script>

<template>
  <div>
    <gl-button
      v-gl-tooltip
      class="@md/panel:gl-hidden"
      icon="preferences"
      :title="__('Display')"
      :aria-label="__('Display')"
      :selected="selected"
      data-testid="display-settings-icon-button"
      @click="$emit('click')"
    />
    <gl-button
      class="gl-hidden @md/panel:gl-inline-flex"
      icon="preferences"
      :selected="selected"
      data-testid="display-settings-label-button"
      @click="$emit('click')"
    >
      {{ __('Display') }}
    </gl-button>
  </div>
</template>
