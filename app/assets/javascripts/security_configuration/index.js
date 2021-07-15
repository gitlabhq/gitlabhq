import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBooleanDataAttributes } from '~/lib/utils/dom_utils';
import SecurityConfigurationApp from './components/app.vue';
import { securityFeatures, complianceFeatures } from './components/constants';
import RedesignedSecurityConfigurationApp from './components/redesigned_app.vue';
import { augmentFeatures } from './utils';

export const initRedesignedSecurityConfiguration = (el) => {
  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    projectPath,
    upgradePath,
    features,
    latestPipelinePath,
    gitlabCiHistoryPath,
    autoDevopsHelpPagePath,
    autoDevopsPath,
  } = el.dataset;

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
      autoDevopsHelpPagePath,
      autoDevopsPath,
    },
    render(createElement) {
      return createElement(RedesignedSecurityConfigurationApp, {
        props: {
          augmentedComplianceFeatures,
          augmentedSecurityFeatures,
          latestPipelinePath,
          gitlabCiHistoryPath,
          ...parseBooleanDataAttributes(el, [
            'gitlabCiPresent',
            'autoDevopsEnabled',
            'canEnableAutoDevops',
          ]),
        },
      });
    },
  });
};

export const initCESecurityConfiguration = (el) => {
  if (!el) {
    return null;
  }

  if (gon.features?.securityConfigurationRedesign) {
    return initRedesignedSecurityConfiguration(el);
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { projectPath, upgradePath } = el.dataset;

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
