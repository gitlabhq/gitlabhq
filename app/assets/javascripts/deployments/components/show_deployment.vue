<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import { toggleQueryPollingByVisibility, etagQueryHeaders } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import deploymentQuery from '../graphql/queries/deployment.query.graphql';
import environmentQuery from '../graphql/queries/environment.query.graphql';
import DeploymentHeader from './deployment_header.vue';
import DeploymentAside from './deployment_aside.vue';
import DeploymentDeployBlock from './deployment_deploy_block.vue';
import DetailsFeedback from './details_feedback.vue';

const DEPLOYMENT_QUERY_POLLING_INTERVAL = 3000;

export default {
  components: {
    GlAlert,
    GlSprintf,
    DeploymentHeader,
    DeploymentAside,
    DeploymentDeployBlock,
    DetailsFeedback,
    DeploymentApprovals: () =>
      import('ee_component/deployments/components/deployment_approvals.vue'),
    DeploymentTimeline: () => import('ee_component/deployments/components/deployment_timeline.vue'),
  },
  inject: ['projectPath', 'deploymentIid', 'environmentName', 'graphqlEtagKey'],
  apollo: {
    deployment: {
      query: deploymentQuery,
      variables() {
        return { fullPath: this.projectPath, iid: this.deploymentIid };
      },
      update(data) {
        return data?.project?.deployment;
      },
      error(error) {
        captureException(error);
        this.errorMessage = this.$options.i18n.errorMessage;
      },
      context() {
        return etagQueryHeaders('deployment_details', this.graphqlEtagKey);
      },
      poll: DEPLOYMENT_QUERY_POLLING_INTERVAL,
    },
    environment: {
      query: environmentQuery,
      variables() {
        return { fullPath: this.projectPath, name: this.environmentName };
      },
      update(data) {
        return data?.project?.environment;
      },
      error(error) {
        captureException(error);
        this.errorMessage = this.$options.i18n.errorMessage;
      },
    },
  },
  data() {
    return { deployment: {}, environment: {}, errorMessage: '' };
  },
  computed: {
    hasError() {
      return Boolean(this.errorMessage);
    },
    hasApprovalSummary() {
      return Boolean(this.deployment.approvalSummary);
    },
    isManual() {
      return this.deployment.job?.manualJob;
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(
      this.$apollo.queries.deployment,
      DEPLOYMENT_QUERY_POLLING_INTERVAL,
    );
  },
  i18n: {
    header: s__('Deployment|Deployment #%{iid}'),
    errorMessage: s__(
      'Deployment|There was an issue fetching the deployment, please try again later.',
    ),
  },
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between">
      <div class="gl-flex-grow-1">
        <h1 class="page-title gl-font-size-h-display">
          <gl-sprintf :message="$options.i18n.header">
            <template #iid>{{ deploymentIid }}</template>
          </gl-sprintf>
        </h1>
        <gl-alert v-if="hasError" variant="danger">{{ errorMessage }}</gl-alert>
        <deployment-header
          v-else
          :deployment="deployment"
          :environment="environment"
          :loading="$apollo.queries.deployment.loading"
        />
        <details-feedback class="gl-mt-6 gl-w-90p" />
        <deployment-approvals
          v-if="hasApprovalSummary"
          :approval-summary="deployment.approvalSummary"
          :deployment="deployment"
          class="gl-mt-6 gl-w-90p"
          @change="$apollo.queries.deployment.refetch()"
        />
        <deployment-deploy-block
          v-if="isManual"
          :deployment="deployment"
          class="gl-w-90p gl-mt-4"
        />
        <deployment-timeline
          v-if="hasApprovalSummary"
          :approval-summary="deployment.approvalSummary"
          class="gl-w-90p"
        />
      </div>
      <deployment-aside
        v-if="!hasError"
        :loading="$apollo.queries.deployment.loading"
        :deployment="deployment"
        :environment="environment"
        class="gl-w-20p"
      />
    </div>
  </div>
</template>
