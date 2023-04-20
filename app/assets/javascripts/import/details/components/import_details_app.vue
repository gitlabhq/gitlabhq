<script>
import { s__ } from '~/locale';
import ImportDetailsTable from './import_details_table.vue';

export default {
  components: { ImportDetailsTable },
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
    <import-details-table />
  </div>
</template>
