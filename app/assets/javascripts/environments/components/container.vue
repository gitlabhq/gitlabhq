<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLoadingIcon } from '@gitlab/ui';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import EnvironmentTable from './environments_table.vue';

export default {
  components: {
    EnvironmentTable,
    TablePagination,
    GlLoadingIcon,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    environments: {
      type: Array,
      required: true,
    },
    pagination: {
      type: Object,
      required: true,
    },
  },
  methods: {
    onChangePage(page) {
      this.$emit('onChangePage', page);
    },
  },
};
</script>

<template>
  <div class="environments-container">
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-3" label="Loading environments" />

    <slot name="empty-state"></slot>

    <div v-if="!isLoading && environments.length > 0" class="table-holder">
      <environment-table :environments="environments" />

      <table-pagination
        v-if="pagination && pagination.totalPages > 1"
        :change="onChangePage"
        :page-info="pagination"
      />
    </div>
  </div>
</template>
