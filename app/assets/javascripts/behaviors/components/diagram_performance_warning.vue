<script>
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'DiagramPerformanceWarning',
  i18n: {
    bodyText: __('Warning: Displaying this diagram might cause performance issues on this page.'),
    buttonText: __('Display'),
  },
  components: {
    GlAlert,
  },
  emits: ['close-alert', 'show-image'],
};
</script>

<template>
  <gl-alert
    data-testid="diagram-performance-warning"
    :primary-button-text="$options.i18n.buttonText"
    variant="warning"
    @dismiss="$emit('close-alert')"
    @primary-action="$emit('show-image')"
  >
    {{ $options.i18n.bodyText }}
  </gl-alert>
</template>
