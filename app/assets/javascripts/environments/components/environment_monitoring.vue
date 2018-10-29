<script>
/**
 * Renders the Monitoring (Metrics) link in environments table.
 */
import { GlButton } from '@gitlab-org/gitlab-ui';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  components: {
    Icon,
    GlButton,
  },
  directives: {
    tooltip,
  },
  props: {
    monitoringUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    title() {
      return 'Monitoring';
    },
  },
};
</script>
<template>
  <gl-button
    v-tooltip
    :href="monitoringUrl"
    :title="title"
    :aria-label="title"
    class="monitoring-url d-none d-sm-none d-md-block"
    data-container="body"
    rel="noopener noreferrer nofollow"
    variant="default"
  >
    <icon name="chart" />
  </gl-button>
</template>
