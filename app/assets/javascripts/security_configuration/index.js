import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import SecurityConfigurationApp from './components/app.vue';
import { securityFeatures, complianceFeatures } from './components/constants';
import RedesignedSecurityConfigurationApp from './components/redesigned_app.vue';
import { augmentFeatures } from './utils';

export const initStaticSecurityConfiguration = (el) => {
  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { projectPath, upgradePath, features, latestPipelinePath } = el.dataset;

  if (gon.features.securityConfigurationRedesign) {
    const { augmentedSecurityFeatures, augmentedComplianceFeatures } = augmentFeatures(
      securityFeatures,
      complianceFeatures,
      features ? JSON.parse(features) : [],
    );

    return new Vue({
      el,
      apolloProvider,
      provide: {
        projectPath,
        upgradePath,
      },
      render(createElement) {
        return createElement(RedesignedSecurityConfigurationApp, {
          props: {
            augmentedComplianceFeatures,
            augmentedSecurityFeatures,
            latestPipelinePath,
          },
        });
      },
    });
  }
  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
      upgradePath,
    },
    render(createElement) {
      return createElement(SecurityConfigurationApp);
    },
  });
};
