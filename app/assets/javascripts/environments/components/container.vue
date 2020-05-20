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
    canaryDeploymentFeatureId: {
      type: String,
      required: false,
      default: null,
    },
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
    deployBoardsHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    helpCanaryDeploymentsPath: {
      type: String,
      required: false,
      default: '',
    },
    lockPromotionSvgPath: {
      type: String,
      required: false,
      default: '',
    },
    showCanaryDeploymentCallout: {
      type: Boolean,
      required: false,
      default: false,
    },
    userCalloutsPath: {
      type: String,
      required: false,
      default: '',
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
      size="md"
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
