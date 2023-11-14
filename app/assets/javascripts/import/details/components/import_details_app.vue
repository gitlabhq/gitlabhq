<script>
import { __ } from '~/locale';
import ImportDetailsTable from './import_details_table.vue';

export default {
  name: 'ImportDetailsApp',
  components: { ImportDetailsTable },

  fields: [
    {
      key: 'type',
      label: __('Type'),
      tdClass: 'gl-white-space-nowrap',
    },
    {
      key: 'title',
      label: __('Title'),
      tdClass: 'gl-md-w-30 gl-word-break-word',
    },
    {
      key: 'provider_url',
      label: __('URL'),
      tdClass: 'gl-white-space-nowrap',
    },
    {
      key: 'details',
      label: __('Details'),
    },
  ],

  LOCAL_STORAGE_KEY: 'gl-import-details-page-size',
};
</script>

<template>
  <div>
    <h1>{{ s__('Import|GitHub import details') }}</h1>

    <import-details-table
      :fields="$options.fields"
      :local-storage-key="$options.LOCAL_STORAGE_KEY"
    />
  </div>
</template>
