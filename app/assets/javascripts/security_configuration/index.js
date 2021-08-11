import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBooleanDataAttributes } from '~/lib/utils/dom_utils';
import SecurityConfigurationApp from './components/app.vue';
import { securityFeatures, complianceFeatures } from './components/constants';
import { augmentFeatures } from './utils';

export const initSecurityConfiguration = (el) => {
  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient({}, { assumeImmutableResults: true }),
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
      return createElement(SecurityConfigurationApp, {
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
