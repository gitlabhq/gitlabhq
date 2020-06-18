<script>
import { escape, isEmpty } from 'lodash';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import { sprintf, __ } from '../../locale';

export default {
  components: {
    CiIcon,
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
      switch (this.deploymentStatus.status) {
        case 'last':
          return this.lastEnvironmentMessage();
        case 'out_of_date':
          return this.outOfDateEnvironmentMessage();
        case 'failed':
          return this.failedEnvironmentMessage();
        case 'creating':
          return this.creatingEnvironmentMessage();
        default:
          return '';
      }
    },
    environmentLink() {
      if (this.hasEnvironment) {
        return sprintf(
          '%{startLink}%{name}%{endLink}',
          {
            startLink: `<a href="${this.deploymentStatus.environment.environment_path}" class="js-environment-link">`,
            name: escape(this.deploymentStatus.environment.name),
            endLink: '</a>',
          },
          false,
        );
      }
      return '';
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
      const escapedName = escape(name);
      const escapedPath = escape(path);

      if (!escapedPath) {
        return escapedName;
      }

      return sprintf(
        '%{startLink}%{name}%{endLink}',
        {
          startLink: `<a href="${escapedPath}" class="js-job-cluster-link">`,
          name: escapedName,
          endLink: '</a>',
        },
        false,
      );
    },
    kubernetesNamespace() {
      return this.hasCluster ? this.deploymentCluster.kubernetes_namespace : null;
    },
  },
  methods: {
    deploymentLink(name) {
      return sprintf(
        '%{startLink}%{name}%{endLink}',
        {
          startLink: `<a href="${this.lastDeploymentPath}" class="js-job-deployment-link">`,
          name,
          endLink: '</a>',
        },
        false,
      );
    },
    failedEnvironmentMessage() {
      const { environmentLink } = this;

      return sprintf(
        __('The deployment of this job to %{environmentLink} did not succeed.'),
        { environmentLink },
        false,
      );
    },
    lastEnvironmentMessage() {
      const { environmentLink, clusterNameOrLink, hasCluster, kubernetesNamespace } = this;
      if (hasCluster) {
        if (kubernetesNamespace) {
          return sprintf(
            __(
              'This job is deployed to %{environmentLink} using cluster %{clusterNameOrLink} and namespace %{kubernetesNamespace}.',
            ),
            { environmentLink, clusterNameOrLink, kubernetesNamespace },
            false,
          );
        }
        // we know the cluster but not the namespace
        return sprintf(
          __('This job is deployed to %{environmentLink} using cluster %{clusterNameOrLink}.'),
          { environmentLink, clusterNameOrLink },
          false,
        );
      }
      // not a cluster deployment
      return sprintf(__('This job is deployed to %{environmentLink}.'), { environmentLink }, false);
    },
    outOfDateEnvironmentMessage() {
      const {
        hasLastDeployment,
        hasCluster,
        environmentLink,
        clusterNameOrLink,
        kubernetesNamespace,
      } = this;

      if (hasLastDeployment) {
        const deploymentLink = this.deploymentLink(__('most recent deployment'));
        if (hasCluster) {
          if (kubernetesNamespace) {
            return sprintf(
              __(
                'This job is an out-of-date deployment to %{environmentLink} using cluster %{clusterNameOrLink} and namespace %{kubernetesNamespace}. View the %{deploymentLink}.',
              ),
              { environmentLink, clusterNameOrLink, kubernetesNamespace, deploymentLink },
              false,
            );
          }
          // we know the cluster but not the namespace
          return sprintf(
            __(
              'This job is an out-of-date deployment to %{environmentLink} using cluster %{clusterNameOrLink}. View the %{deploymentLink}.',
            ),
            { environmentLink, clusterNameOrLink, deploymentLink },
            false,
          );
        }
        // not a cluster deployment
        return sprintf(
          __(
            'This job is an out-of-date deployment to %{environmentLink}. View the %{deploymentLink}.',
          ),
          { environmentLink, deploymentLink },
          false,
        );
      }
      // no last deployment, i.e. this is the first deployment
      if (hasCluster) {
        if (kubernetesNamespace) {
          return sprintf(
            __(
              'This job is an out-of-date deployment to %{environmentLink} using cluster %{clusterNameOrLink} and namespace %{kubernetesNamespace}.',
            ),
            { environmentLink, clusterNameOrLink, kubernetesNamespace },
            false,
          );
        }
        // we know the cluster but not the namespace
        return sprintf(
          __(
            'This job is an out-of-date deployment to %{environmentLink} using cluster %{clusterNameOrLink}.',
          ),
          { environmentLink, clusterNameOrLink },
          false,
        );
      }
      // not a cluster deployment
      return sprintf(
        __('This job is an out-of-date deployment to %{environmentLink}.'),
        { environmentLink },
        false,
      );
    },
    creatingEnvironmentMessage() {
      const {
        hasLastDeployment,
        hasCluster,
        environmentLink,
        clusterNameOrLink,
        kubernetesNamespace,
      } = this;

      if (hasLastDeployment) {
        const deploymentLink = this.deploymentLink(__('latest deployment'));
        if (hasCluster) {
          if (kubernetesNamespace) {
            return sprintf(
              __(
                'This job is creating a deployment to %{environmentLink} using cluster %{clusterNameOrLink} and namespace %{kubernetesNamespace}. This will overwrite the %{deploymentLink}.',
              ),
              { environmentLink, clusterNameOrLink, kubernetesNamespace, deploymentLink },
              false,
            );
          }
          // we know the cluster but not the namespace
          return sprintf(
            __(
              'This job is creating a deployment to %{environmentLink} using cluster %{clusterNameOrLink}. This will overwrite the %{deploymentLink}.',
            ),
            { environmentLink, clusterNameOrLink, deploymentLink },
            false,
          );
        }
        // not a cluster deployment
        return sprintf(
          __(
            'This job is creating a deployment to %{environmentLink}. This will overwrite the %{deploymentLink}.',
          ),
          { environmentLink, deploymentLink },
          false,
        );
      }
      // no last deployment, i.e. this is the first deployment
      if (hasCluster) {
        if (kubernetesNamespace) {
          return sprintf(
            __(
              'This job is creating a deployment to %{environmentLink} using cluster %{clusterNameOrLink} and namespace %{kubernetesNamespace}.',
            ),
            { environmentLink, clusterNameOrLink, kubernetesNamespace },
            false,
          );
        }
        // we know the cluster but not the namespace
        return sprintf(
          __(
            'This job is creating a deployment to %{environmentLink} using cluster %{clusterNameOrLink}.',
          ),
          { environmentLink, clusterNameOrLink },
          false,
        );
      }
      // not a cluster deployment
      return sprintf(
        __('This job is creating a deployment to %{environmentLink}.'),
        { environmentLink },
        false,
      );
    },
  },
};
</script>
<template>
  <div class="prepend-top-default append-bottom-default js-environment-container">
    <div class="environment-information">
      <ci-icon :status="iconStatus" />
      <p class="inline gl-mb-0" v-html="environment"></p>
    </div>
  </div>
</template>
