<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('CiCatalog|Get started with the CI/CD Catalog'),
    description: s__(
      'CiCatalog|Create a pipeline component repository and make reusing pipeline configurations faster and easier.',
    ),
  },
  name: 'CiCatalogEmptyState',
  components: {
    GlEmptyState,
  },
};
</script>
<template>
  <div>
    <gl-empty-state :title="$options.i18n.title" :description="$options.i18n.description" />
  </div>
</template>
