<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { UPGRADE_CTA } from './constants';

export default {
  components: {
    GlLink,
    GlSprintf,
  },
  inject: {
    upgradePath: {
      from: 'upgradePath',
      default: '#',
    },
  },
  i18n: {
    UPGRADE_CTA,
  },
};
</script>

<template>
  <span>
    <gl-sprintf :message="$options.i18n.UPGRADE_CTA">
      <template #link="{ content }">
        <gl-link target="_blank" :href="upgradePath">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </span>
</template>
