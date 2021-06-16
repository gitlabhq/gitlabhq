import Vue from 'vue';
import RunnerAwsDeployments from '~/vue_shared/components/runner_aws_deployments/runner_aws_deployments.vue';

export function initRunnerAwsDeployments(componentId = 'js-runner-aws-deployments') {
  const el = document.getElementById(componentId);

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(RunnerAwsDeployments);
    },
  });
}
