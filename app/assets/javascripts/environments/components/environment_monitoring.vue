<script>
import { GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
/**
 * Renders the Monitoring (Metrics) link in environments table.
 */
export default {
  components: {
    GlDropdownItem,
  },
  props: {
    monitoringUrl: {
      type: String,
      required: true,
    },
  },
  title: __('Monitoring'),
};
</script>
<template>
  <gl-dropdown-item :href="monitoringUrl" rel="noopener noreferrer nofollow" target="_blank">
    {{ $options.title }}
  </gl-dropdown-item>
</template>
