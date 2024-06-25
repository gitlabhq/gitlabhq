<script>
import NO_DATA_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg?url';
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  NO_DATA_SVG,
  i18n: {
    title: s__('Observability|Sorry, your filter produced no results'),
    description: s__('Observability|To widen your search, change or remove filters above'),
  },
  components: {
    GlEmptyState,
  },
};
</script>

<template>
  <gl-empty-state :title="$options.i18n.title" :svg-path="$options.NO_DATA_SVG" :svg-height="null">
    <template #description>
      <span>{{ $options.i18n.description }}</span>
    </template>
  </gl-empty-state>
</template>
