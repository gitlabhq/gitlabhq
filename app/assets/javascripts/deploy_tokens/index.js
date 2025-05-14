import Vue from 'vue';
import NewDeployToken from 'ee_else_ce/deploy_tokens/components/new_deploy_token.vue';

export default function initDeployTokens() {
  const el = document.getElementById('js-new-deploy-token');

  if (el == null) return null;

  const {
    createNewTokenPath,
    deployTokensHelpUrl,
    containerRegistryEnabled,
    dependencyProxyEnabled,
    packagesRegistryEnabled,
    topLevelGroup,
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
          dependencyProxyEnabled: dependencyProxyEnabled !== undefined,
          packagesRegistryEnabled: packagesRegistryEnabled !== undefined,
          topLevelGroup: topLevelGroup !== undefined,
          tokenType,
        },
      });
    },
  });
}
