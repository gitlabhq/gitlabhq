<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ValueStreamsDashboardLink',
  components: { GlIcon, GlLink },
  props: {
    requestPath: {
      type: String,
      required: true,
    },
  },
  i18n: {
    title: __('Related'),
    // eslint-disable-next-line @gitlab/require-valid-i18n-helpers
    linkText: __('Value Streams Dashboard | DORA'),
  },
};
</script>
<template>
  <div class="gl-display-flex gl-flex-direction-column" data-testid="vsd-link">
    <div class="gl-display-flex gl-mb-2">
      <span>{{ $options.i18n.title }}</span>
    </div>
    <div class="gl-display-flex gl-align-items-baseline">
      <gl-link :href="requestPath">{{ $options.i18n.linkText }}</gl-link
      >&nbsp;<gl-icon name="dashboard" />
    </div>
  </div>
</template>
