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
  <div class="gl-flex gl-flex-col" data-testid="vsd-link">
    <div class="gl-mb-2 gl-flex">
      <span>{{ $options.i18n.title }}</span>
    </div>
    <div class="gl-flex gl-items-baseline">
      <gl-link :href="requestPath">{{ $options.i18n.linkText }}</gl-link
      >&nbsp;<gl-icon name="dashboard" />
    </div>
  </div>
</template>
