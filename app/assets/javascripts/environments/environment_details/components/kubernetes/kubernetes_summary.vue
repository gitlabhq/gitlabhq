<script>
import { isEmpty } from 'lodash';
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
  props: {
    fluxKustomization: {
      required: true,
      type: Object,
    },
  },
  computed: {
    hasFluxKustomization() {
      return !isEmpty(this.fluxKustomization);
    },
  },
};
</script>
<template>
  <gl-tab :title="$options.i18n.summaryTitle">
    <p class="gl-mt-3 gl-text-secondary">{{ $options.i18n.treeView }}</p>

    <p v-if="hasFluxKustomization">
      {{ fluxKustomization.kind }}: {{ fluxKustomization.metadata.name }}
    </p></gl-tab
  >
</template>
