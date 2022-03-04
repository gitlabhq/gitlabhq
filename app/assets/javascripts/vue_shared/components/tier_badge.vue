<script>
import { GlBadge, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';

const gitlabTiers = {
  free: s__('GitlabTiers|Free'),
  premium: s__('GitlabTiers|Premium'),
  ultimate: s__('GitlabTiers|Ultimate'),
};

export default {
  components: {
    GlBadge,
    GlIcon,
  },
  props: {
    tier: {
      type: String,
      required: true,
      validator: (value) => Object.keys(gitlabTiers).includes(value),
    },
    size: {
      type: String,
      required: false,
      default: 'md',
    },
  },
  computed: {
    tierName() {
      return gitlabTiers[this.tier];
    },
  },
};
</script>

<template>
  <gl-badge :size="size" class="gl-text-purple-600! gl-font-weight-bold gl-bg-purple-50!">
    <gl-icon name="license" /> {{ tierName }}
  </gl-badge>
</template>
