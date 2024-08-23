<script>
import { sprintf, s__, __ } from '~/locale';

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
      tdClass: 'gl-whitespace-nowrap',
    },
    {
      key: 'source_title',
      label: __('Title'),
      tdClass: 'md:gl-w-30 gl-break-anywhere',
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

  props: {
    id: {
      type: String,
      required: false,
      default: null,
    },
    entityId: {
      type: String,
      required: false,
      default: null,
    },
    fullPath: {
      type: String,
      required: false,
      default: null,
    },
  },

  computed: {
    title() {
      return sprintf(s__('BulkImport|Items that failed to be imported for %{id}'), {
        id: this.fullPath || this.entityId,
      });
    },
  },
};
</script>

<template>
  <div>
    <h1 class="gl-my-0 gl-flex gl-items-center gl-gap-3 gl-py-4 gl-text-size-h1">
      <img :src="$options.gitlabLogo" class="gl-h-6 gl-w-6" />
      <span>{{ title }}</span>
    </h1>

    <import-details-table
      :id="id"
      bulk-import
      :entity-id="entityId"
      :fields="$options.fields"
      :local-storage-key="$options.LOCAL_STORAGE_KEY"
    />
  </div>
</template>
