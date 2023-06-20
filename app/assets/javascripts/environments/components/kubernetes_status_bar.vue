<script>
import { GlLoadingIcon, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import { HEALTH_BADGES } from '../constants';

export default {
  components: {
    GlLoadingIcon,
    GlBadge,
  },
  props: {
    clusterHealthStatus: {
      required: false,
      type: String,
      default: '',
      validator(val) {
        return ['error', 'success', ''].includes(val);
      },
    },
  },
  computed: {
    healthBadge() {
      return HEALTH_BADGES[this.clusterHealthStatus];
    },
  },
  i18n: {
    healthLabel: s__('Environment|Environment health'),
  },
};
</script>
<template>
  <div class="gl-display-flex gl-align-items-center gl-mr-3 gl-mb-2">
    <span class="gl-font-sm gl-font-monospace gl-mr-3">{{ $options.i18n.healthLabel }}</span>
    <gl-loading-icon v-if="!clusterHealthStatus" size="sm" inline />
    <gl-badge v-else-if="healthBadge" :variant="healthBadge.variant">
      {{ healthBadge.text }}
    </gl-badge>
  </div>
</template>
