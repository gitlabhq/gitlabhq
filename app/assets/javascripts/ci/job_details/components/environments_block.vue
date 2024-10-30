<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { __ } from '~/locale';

const STATUS_LAST = 'last';
const STATUS_CREATING = 'creating';
const STATUS_OUT_OF_DATE = 'out_of_date';
const STATUS_FAILED = 'failed';

export default {
  components: {
    CiIcon,
    GlLink,
    GlSprintf,
  },
  props: {
    deploymentStatus: {
      type: Object,
      required: true,
    },
    deploymentCluster: {
      type: Object,
      required: false,
      default: null,
    },
    iconStatus: {
      type: Object,
      required: true,
    },
  },
  computed: {
    environment() {
      const statusMessages = {
        [STATUS_LAST]: this.lastEnvironmentMessage,
        [STATUS_OUT_OF_DATE]: this.outOfDateEnvironmentMessage,
        [STATUS_FAILED]: this.failedEnvironmentMessage,
        [STATUS_CREATING]: this.creatingEnvironmentMessage,
      };

      return statusMessages[this.deploymentStatus.status] || '';
    },
    environmentLink() {
      if (this.hasEnvironment) {
        return {
          link: this.deploymentStatus.environment.environment_path,
          name: this.deploymentStatus.environment.name,
        };
      }
      return {};
    },
    hasLastDeployment() {
      return this.hasEnvironment && this.deploymentStatus.environment.last_deployment;
    },
    lastDeployment() {
      return this.hasLastDeployment ? this.deploymentStatus.environment.last_deployment : {};
    },
    hasEnvironment() {
      return !isEmpty(this.deploymentStatus.environment);
    },
    lastDeploymentPath() {
      return !isEmpty(this.lastDeployment.deployable)
        ? this.lastDeployment.deployable.build_path
        : '';
    },
    hasCluster() {
      return Boolean(this.deploymentCluster) && Boolean(this.deploymentCluster.name);
    },
    clusterNameOrLink() {
      if (!this.hasCluster) {
        return '';
      }

      const { name, path } = this.deploymentCluster;

      return {
        path,
        name,
      };
    },
    kubernetesNamespace() {
      return this.hasCluster ? this.deploymentCluster.kubernetes_namespace : null;
    },
    deploymentLink() {
      return {
        path: this.lastDeploymentPath,
        name:
          this.deploymentStatus.status === STATUS_CREATING
            ? __('latest deployment')
            : __('most recent deployment'),
      };
    },
    lastEnvironmentMessage() {
      if (this.hasCluster) {
        if (this.kubernetesNamespace) {
          return __(
            'This job is deployed to %{environmentLink} using cluster %{clusterNameOrLink} and namespace %{kubernetesNamespace}.',
          );
        }
        // we know the cluster but not the namespace
        return __('This job is deployed to %{environmentLink} using cluster %{clusterNameOrLink}.');
      }
      // not a cluster deployment
      return __('This job is deployed to %{environmentLink}.');
    },
    outOfDateEnvironmentMessage() {
      if (this.hasLastDeployment) {
        if (this.hasCluster) {
          if (this.kubernetesNamespace) {
            return __(
              'This job is an out-of-date deployment to %{environmentLink} using cluster %{clusterNameOrLink} and namespace %{kubernetesNamespace}. View the %{deploymentLink}.',
            );
          }
          // we know the cluster but not the namespace
          return __(
            'This job is an out-of-date deployment to %{environmentLink} using cluster %{clusterNameOrLink}. View the %{deploymentLink}.',
          );
        }
        // not a cluster deployment
        return __(
          'This job is an out-of-date deployment to %{environmentLink}. View the %{deploymentLink}.',
        );
      }
      // no last deployment, i.e. this is the first deployment
      if (this.hasCluster) {
        if (this.kubernetesNamespace) {
          return __(
            'This job is an out-of-date deployment to %{environmentLink} using cluster %{clusterNameOrLink} and namespace %{kubernetesNamespace}.',
          );
        }
        // we know the cluster but not the namespace
        return __(
          'This job is an out-of-date deployment to %{environmentLink} using cluster %{clusterNameOrLink}.',
        );
      }
      // not a cluster deployment
      return __('This job is an out-of-date deployment to %{environmentLink}.');
    },
    creatingEnvironmentMessage() {
      if (this.hasLastDeployment) {
        if (this.hasCluster) {
          if (this.kubernetesNamespace) {
            return __(
              'This job is creating a deployment to %{environmentLink} using cluster %{clusterNameOrLink} and namespace %{kubernetesNamespace}. This will overwrite the %{deploymentLink}.',
            );
          }
          // we know the cluster but not the namespace
          return __(
            'This job is creating a deployment to %{environmentLink} using cluster %{clusterNameOrLink}. This will overwrite the %{deploymentLink}.',
          );
        }
        // not a cluster deployment
        return __(
          'This job is creating a deployment to %{environmentLink}. This will overwrite the %{deploymentLink}.',
        );
      }
      // no last deployment, i.e. this is the first deployment
      if (this.hasCluster) {
        if (this.kubernetesNamespace) {
          return __(
            'This job is creating a deployment to %{environmentLink} using cluster %{clusterNameOrLink} and namespace %{kubernetesNamespace}.',
          );
        }
        // we know the cluster but not the namespace
        return __(
          'This job is creating a deployment to %{environmentLink} using cluster %{clusterNameOrLink}.',
        );
      }
      // not a cluster deployment
      return __('This job is creating a deployment to %{environmentLink}.');
    },
    failedEnvironmentMessage() {
      return __('The deployment of this job to %{environmentLink} did not succeed.');
    },
  },
};
</script>
<template>
  <div class="gl-my-4" data-testid="jobs-environment-container">
    <div
      class="gl-border gl-flex gl-gap-3 gl-rounded-base gl-bg-subtle gl-p-4"
      data-testid="jobs-environment-info"
    >
      <ci-icon :status="iconStatus" />
      <p class="gl-mb-0 gl-inline-block gl-self-center">
        <gl-sprintf :message="environment">
          <template #environmentLink>
            <gl-link
              v-if="hasEnvironment"
              :href="environmentLink.link"
              data-testid="job-environment-link"
              >{{ environmentLink.name }}</gl-link
            >
          </template>
          <template #clusterNameOrLink>
            <gl-link
              v-if="clusterNameOrLink.path"
              :href="clusterNameOrLink.path"
              data-testid="job-cluster-link"
              >{{ clusterNameOrLink.name }}</gl-link
            >
            <template v-else>{{ clusterNameOrLink.name }}</template>
          </template>
          <template #kubernetesNamespace>{{ kubernetesNamespace }}</template>
          <template #deploymentLink>
            <gl-link :href="deploymentLink.path" data-testid="job-deployment-link">{{
              deploymentLink.name
            }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
  </div>
</template>
