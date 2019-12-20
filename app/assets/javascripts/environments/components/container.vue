<script>
import { GlLoadingIcon } from '@gitlab/ui';
import containerMixin from 'ee_else_ce/environments/mixins/container_mixin';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import EnvironmentTable from '../components/environments_table.vue';

export default {
  components: {
    EnvironmentTable,
    TablePagination,
    GlLoadingIcon,
  },
  mixins: [containerMixin],
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
    <gl-loading-icon
      v-if="isLoading"
      :size="3"
      class="prepend-top-default"
      label="Loading environments"
    />

    <slot name="emptyState"></slot>

    <div v-if="!isLoading && environments.length > 0" class="table-holder">
      <environment-table
        :environments="environments"
        :can-read-environment="canReadEnvironment"
        :canary-deployment-feature-id="canaryDeploymentFeatureId"
        :show-canary-deployment-callout="showCanaryDeploymentCallout"
        :user-callouts-path="userCalloutsPath"
        :lock-promotion-svg-path="lockPromotionSvgPath"
        :help-canary-deployments-path="helpCanaryDeploymentsPath"
        :deploy-boards-help-path="deployBoardsHelpPath"
      />

      <table-pagination
        v-if="pagination && pagination.totalPages > 1"
        :change="onChangePage"
        :page-info="pagination"
      />
    </div>
  </div>
</template>
