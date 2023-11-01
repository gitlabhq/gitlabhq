<script>
import ImportDetailsTable from '~/import/details/components/import_details_table.vue';

export default {
  name: 'BulkImportDetailsApp',
  components: { ImportDetailsTable },
};
</script>

<template>
  <div>
    <h1>{{ s__('Import|GitLab Migration details') }}</h1>
    <import-details-table />
  </div>
</template>
