<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

export default {
  i18n: {
    requiredPython: s__('PackageRegistry|Required Python: %{pythonVersion}'),
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
    <details-row icon="information-o" padding="gl-p-4" data-testid="pypi-required-python">
      <gl-sprintf :message="$options.i18n.requiredPython">
        <template #pythonVersion>
          <strong>{{ packageMetadata.requiredPython }}</strong>
        </template>
      </gl-sprintf>
    </details-row>
  </div>
</template>
