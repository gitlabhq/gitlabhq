<script>
import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlLoadingIcon,
    GlTable,
  },
  props: {
    alert: {
      type: Object,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  tableHeader: {
    [s__('AlertManagement|Full Alert Payload')]: s__('AlertManagement|Value'),
  },
  computed: {
    items() {
      if (!this.alert) {
        return [];
      }
      return [{ ...this.$options.tableHeader, ...this.alert }];
    },
  },
};
</script>
<template>
  <gl-table
    class="alert-management-details-table"
    :busy="loading"
    :empty-text="s__('AlertManagement|No alert data to display.')"
    :items="items"
    show-empty
    stacked
  >
    <template #table-busy>
      <gl-loading-icon size="lg" color="dark" class="gl-mt-5" />
    </template>
  </gl-table>
</template>
