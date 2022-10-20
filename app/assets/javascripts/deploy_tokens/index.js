import Vue from 'vue';
import NewDeployToken from './components/new_deploy_token.vue';

export default function initDeployTokens() {
  const el = document.getElementById('js-new-deploy-token');

  if (el == null) return null;

  const {
    createNewTokenPath,
    deployTokensHelpUrl,
    containerRegistryEnabled,
    packagesRegistryEnabled,
    tokenType,
  } = el.dataset;
  return new Vue({
    el,
    components: {
      NewDeployToken,
    },
    render(createElement) {
      return createElement(NewDeployToken, {
        props: {
          createNewTokenPath,
          deployTokensHelpUrl,
          containerRegistryEnabled: containerRegistryEnabled !== undefined,
          packagesRegistryEnabled: packagesRegistryEnabled !== undefined,
          tokenType,
        },
      });
    },
  });
}
