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
    [s__('AlertManagement|Key')]: s__('AlertManagement|Value'),
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
    class="alert-management-details-table gl-mb-0!"
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
