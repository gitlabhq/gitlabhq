<script>
import { __ } from '~/locale';
import ImportDetailsTable from '~/import/details/components/import_details_table.vue';

export default {
  name: 'BulkImportDetailsApp',
  components: { ImportDetailsTable },

  fields: [
    {
      key: 'relation',
      label: __('Type'),
      tdClass: 'gl-white-space-nowrap',
    },
    {
      key: 'source_title',
      label: __('Title'),
      tdClass: 'gl-md-w-30 gl-word-break-word',
    },
    {
      key: 'error',
      label: __('Error'),
    },
    {
      key: 'correlation_id_value',
      label: __('Correlation ID'),
    },
  ],

  LOCAL_STORAGE_KEY: 'gl-bulk-import-details-page-size',
};
</script>

<template>
  <div>
    <h1>{{ s__('Import|GitLab Migration details') }}</h1>

    <import-details-table
      bulk-import
      :fields="$options.fields"
      :local-storage-key="$options.LOCAL_STORAGE_KEY"
    />
  </div>
</template>
