<script>
import { GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlTab,
  },
  i18n: {
    summaryTitle: s__('Environment|Summary'),
    treeView: s__('Environment|Tree view'),
  },
};
</script>
<template>
  <gl-tab :title="$options.i18n.summaryTitle">
    <p class="gl-mt-3 gl-text-secondary">{{ $options.i18n.treeView }}</p>
  </gl-tab>
</template>
