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
      let environmentText;
      switch (this.deploymentStatus.status) {
        case 'last':
          environmentText = sprintf(
            __('This job is the most recent deployment to %{link}.'),
            { link: this.environmentLink },
            false,
          );
          break;
        case 'out_of_date':
          if (this.hasLastDeployment) {
            environmentText = sprintf(
              __(
                'This job is an out-of-date deployment to %{environmentLink}. View the most recent deployment %{deploymentLink}.',
              ),
              {
                environmentLink: this.environmentLink,
                deploymentLink: this.deploymentLink(`#${this.lastDeployment.iid}`),
              },
              false,
            );
          } else {
            environmentText = sprintf(
              __('This job is an out-of-date deployment to %{environmentLink}.'),
              { environmentLink: this.environmentLink },
              false,
            );
          }

          break;
        case 'failed':
          environmentText = sprintf(
            __('The deployment of this job to %{environmentLink} did not succeed.'),
            { environmentLink: this.environmentLink },
            false,
          );
          break;
        case 'creating':
          if (this.hasLastDeployment) {
            environmentText = sprintf(
              __(
                'This job is creating a deployment to %{environmentLink} and will overwrite the %{deploymentLink}.',
              ),
              {
                environmentLink: this.environmentLink,
                deploymentLink: this.deploymentLink(__('latest deployment')),
              },
              false,
            );
          } else {
            environmentText = sprintf(
              __('This job is creating a deployment to %{environmentLink}.'),
              { environmentLink: this.environmentLink },
              false,
            );
          }
          break;
        default:
          break;
      }
      return environmentText;
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
