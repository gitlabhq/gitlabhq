import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import InstallRunnerInstructions from '~/vue_shared/components/runner_instructions/runner_instructions.vue';

Vue.use(VueApollo);

export function initInstallRunner(componentId = 'js-install-runner') {
  const installRunnerEl = document.getElementById(componentId);

  if (installRunnerEl) {
    const defaultClient = createDefaultClient();
    const { projectPath, groupPath } = installRunnerEl.dataset;

    const apolloProvider = new VueApollo({
      defaultClient,
    });

    // eslint-disable-next-line no-new
    new Vue({
      el: installRunnerEl,
      apolloProvider,
      provide: {
        projectPath,
        groupPath,
      },
      render(createElement) {
        return createElement(InstallRunnerInstructions);
      },
    });
  }
}
