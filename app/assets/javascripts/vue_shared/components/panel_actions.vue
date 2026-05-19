<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'PanelActions',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    maximizeUrl: {
      type: String,
      required: false,
      default: null,
    },
  },
  i18n: {
    closePanelText: __('Close panel'),
    maximizePanelText: __('Open in full page'),
  },
  emits: ['close', 'maximize'],
};
</script>

<template>
  <div class="panel-header-inner-actions">
    <slot></slot>

    <div class="panel-header-inner-actions-portal-target js-panel-actions-portal-target"></div>

    <div class="panel-header-panel-actions">
      <gl-button
        v-if="maximizeUrl"
        v-gl-tooltip.bottom="$options.i18n.maximizePanelText"
        :href="maximizeUrl"
        category="tertiary"
        icon="maximize"
        size="small"
        :aria-label="$options.i18n.maximizePanelText"
        @click="$emit('maximize', $event)"
      />

      <gl-button
        v-gl-tooltip.bottom="$options.i18n.closePanelText"
        category="tertiary"
        icon="close"
        size="small"
        :aria-label="$options.i18n.closePanelText"
        @click="$emit('close')"
      />
    </div>
  </div>
</template>
