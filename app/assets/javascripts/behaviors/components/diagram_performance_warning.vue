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
};
</script>

<template>
  <!-- eslint-disable vue/v-on-event-hyphenation -->
  <gl-alert
    :primary-button-text="$options.i18n.buttonText"
    variant="warning"
    @dismiss="$emit('closeAlert')"
    @primaryAction="$emit('showImage')"
  >
    {{ $options.i18n.bodyText }}
  </gl-alert>
  <!-- eslint-enable vue/v-on-event-hyphenation -->
</template>
