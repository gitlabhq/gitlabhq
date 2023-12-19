<script>
import { sprintf, s__, __ } from '~/locale';
import { getParameterValues } from '~/lib/utils/url_utility';

import ImportDetailsTable from '~/import/details/components/import_details_table.vue';

export default {
  name: 'BulkImportDetailsApp',
  components: {
    ImportDetailsTable,
  },

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

  gitlabLogo: window.gon.gitlab_logo,

  computed: {
    title() {
      const id = getParameterValues('entity_id')[0];

      return sprintf(s__('BulkImport|Items that failed to be imported for %{id}'), { id });
    },
  },
};
</script>

<template>
  <div>
    <h1 class="gl-font-size-h1 gl-my-0 gl-py-4 gl-display-flex gl-align-items-center gl-gap-3">
      <img :src="$options.gitlabLogo" class="gl-w-6 gl-h-6" />
      <span>{{ title }}</span>
    </h1>

    <import-details-table
      bulk-import
      :fields="$options.fields"
      :local-storage-key="$options.LOCAL_STORAGE_KEY"
    />
  </div>
</template>
