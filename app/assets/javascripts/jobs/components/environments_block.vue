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
    },
    computed: {
      environment() {
        let environmentText;
        switch (this.deploymentStatus.status) {
          case 'latest':
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
                  deploymentLink: this.deploymentLink,
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
                  'This job is creating a deployment to %{environmentLink} and will overwrite the last %{deploymentLink}.',
                ),
                {
                  environmentLink: this.environmentLink,
                  deploymentLink: this.deploymentLink,
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
        return sprintf(
          '%{startLink}%{name}%{endLink}',
          {
            startLink: `<a href="${this.deploymentStatus.environment.path}">`,
            name: _.escape(this.deploymentStatus.environment.name),
            endLink: '</a>',
          },
          false,
        );
      },
      deploymentLink() {
        return sprintf(
          '%{startLink}%{name}%{endLink}',
          {
            startLink: `<a href="${this.lastDeployment.path}">`,
            name: _.escape(this.lastDeployment.name),
            endLink: '</a>',
          },
          false,
        );
      },
      hasLastDeployment() {
        return this.deploymentStatus.environment.last_deployment;
      },
      lastDeployment() {
        return this.deploymentStatus.environment.last_deployment;
      },
    },
  };
</script>
<template>
  <div class="prepend-top-default js-environment-container">
    <div class="environment-information">
      <ci-icon :status="deploymentStatus.icon" />
      <p v-html="environment"></p>
    </div>
  </div>
</template>
