<script>
import { s__ } from '~/locale';

export default {
  props: {
    project: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  i18n: {
    pageTitle: s__('Import|GitHub import details'),
  },
};
</script>

<template>
  <div>
    <h1>{{ $options.i18n.pageTitle }}</h1>
  </div>
</template>
