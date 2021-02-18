<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { UPGRADE_CTA } from './features_constants';

export default {
  components: {
    GlLink,
    GlSprintf,
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
        <gl-link target="_blank" href="https://about.gitlab.com/pricing/">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </span>
</template>
