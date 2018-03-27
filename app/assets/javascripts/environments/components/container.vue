<script>
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import tablePagination from '../../vue_shared/components/table_pagination.vue';
  import environmentTable from '../components/environments_table.vue';

  export default {
    components: {
      environmentTable,
      loadingIcon,
      tablePagination,
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
      canCreateDeployment: {
        type: Boolean,
        required: true,
      },
      canReadEnvironment: {
        type: Boolean,
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

    <loading-icon
      label="Loading environments"
      v-if="isLoading"
      size="3"
    />

    <slot name="emptyState"></slot>

    <div
      class="table-holder"
      v-if="!isLoading && environments.length > 0">

      <environment-table
        :environments="environments"
        :can-create-deployment="canCreateDeployment"
        :can-read-environment="canReadEnvironment"
      />

      <table-pagination
        v-if="pagination && pagination.totalPages > 1"
        :change="onChangePage"
        :page-info="pagination"
      />
    </div>
  </div>
</template>
