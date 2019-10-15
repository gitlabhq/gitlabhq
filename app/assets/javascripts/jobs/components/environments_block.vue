<script>
import _ from 'underscore';
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
            name: _.escape(this.deploymentStatus.environment.name),
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
      return !_.isEmpty(this.deploymentStatus.environment);
    },
    lastDeploymentPath() {
      return !_.isEmpty(this.lastDeployment.deployable)
        ? this.lastDeployment.deployable.build_path
        : '';
    },
    hasCluster() {
      return this.hasLastDeployment && this.lastDeployment.cluster;
    },
    clusterNameOrLink() {
      if (!this.hasCluster) {
        return '';
      }

      const { name, path } = this.lastDeployment.cluster;
      const escapedName = _.escape(name);
      const escapedPath = _.escape(path);

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
      const { environmentLink, clusterNameOrLink, hasCluster } = this;

      const message = hasCluster
        ? __('This job is deployed to %{environmentLink} using cluster %{clusterNameOrLink}.')
        : __('This job is deployed to %{environmentLink}.');

      return sprintf(message, { environmentLink, clusterNameOrLink }, false);
    },
    outOfDateEnvironmentMessage() {
      const { hasLastDeployment, hasCluster, environmentLink, clusterNameOrLink } = this;

      if (hasLastDeployment) {
        const message = hasCluster
          ? __(
              'This job is an out-of-date deployment to %{environmentLink} using cluster %{clusterNameOrLink}. View the %{deploymentLink}.',
            )
          : __(
              'This job is an out-of-date deployment to %{environmentLink}. View the %{deploymentLink}.',
            );

        return sprintf(
          message,
          {
            environmentLink,
            clusterNameOrLink,
            deploymentLink: this.deploymentLink(__('most recent deployment')),
          },
          false,
        );
      }

      const message = hasCluster
        ? __(
            'This job is an out-of-date deployment to %{environmentLink} using cluster %{clusterNameOrLink}.',
          )
        : __('This job is an out-of-date deployment to %{environmentLink}.');

      return sprintf(
        message,
        {
          environmentLink,
          clusterNameOrLink,
        },
        false,
      );
    },
    creatingEnvironmentMessage() {
      const { hasLastDeployment, hasCluster, environmentLink, clusterNameOrLink } = this;

      if (hasLastDeployment) {
        const message = hasCluster
          ? __(
              'This job is creating a deployment to %{environmentLink} using cluster %{clusterNameOrLink}. This will overwrite the %{deploymentLink}.',
            )
          : __(
              'This job is creating a deployment to %{environmentLink}. This will overwrite the %{deploymentLink}.',
            );

        return sprintf(
          message,
          {
            environmentLink,
            clusterNameOrLink,
            deploymentLink: this.deploymentLink(__('latest deployment')),
          },
          false,
        );
      }

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
      <p class="inline append-bottom-0" v-html="environment"></p>
    </div>
  </div>
</template>
