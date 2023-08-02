<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

export default {
  i18n: {
    appGroup: s__('PackageRegistry|App group: %{group}'),
    appName: s__('PackageRegistry|App name: %{name}'),
  },
  components: {
    DetailsRow,
    GlSprintf,
  },
  props: {
    packageMetadata: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <details-row icon="information-o" padding="gl-p-4" dashed data-testid="maven-app">
      <gl-sprintf :message="$options.i18n.appName">
        <template #name>
          <strong>{{ packageMetadata.appName }}</strong>
        </template>
      </gl-sprintf>
    </details-row>
    <details-row icon="information-o" padding="gl-p-4" data-testid="maven-group">
      <gl-sprintf :message="$options.i18n.appGroup">
        <template #group>
          <strong>{{ packageMetadata.appGroup }}</strong>
        </template>
      </gl-sprintf>
    </details-row>
  </div>
</template>
