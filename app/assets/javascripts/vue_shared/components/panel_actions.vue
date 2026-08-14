<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'PanelActions',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glSlotsMixin],
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

    <div class="panel-header-controls">
      <template v-if="glSlots()['panel-controls']">
        <slot name="panel-controls"></slot>
      </template>
      <template v-else>
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
          data-testid="panel-close-button"
          :aria-label="$options.i18n.closePanelText"
          @click="$emit('close')"
        />
      </template>
    </div>
  </div>
</template>
