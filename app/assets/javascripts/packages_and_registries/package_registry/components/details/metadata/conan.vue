<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

export default {
  i18n: {
    recipeText: s__('PackageRegistry|Recipe: %{recipe}'),
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
    <details-row icon="information-o" padding="gl-p-4" data-testid="conan-recipe">
      <gl-sprintf :message="$options.i18n.recipeText">
        <template #recipe>{{ packageMetadata.recipe }}</template>
      </gl-sprintf>
    </details-row>
  </div>
</template>
