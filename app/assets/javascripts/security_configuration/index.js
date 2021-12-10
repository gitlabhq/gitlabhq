import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBooleanDataAttributes } from '~/lib/utils/dom_utils';
import { __ } from '~/locale';
import SecurityConfigurationApp from './components/app.vue';
import { securityFeatures, complianceFeatures } from './components/constants';
import { augmentFeatures } from './utils';

// Note: this is behind a feature flag and only a placeholder
// until the actual GraphQL fields have been added
// https://gitlab.com/gitlab-org/gi tlab/-/issues/346480
export const tempResolvers = {
  Query: {
    securityTrainingProviders() {
      return [
        {
          __typename: 'SecurityTrainingProvider',
          id: 101,
          name: __('Kontra'),
          description: __('Interactive developer security education.'),
          url: 'https://application.security/',
          isEnabled: false,
        },
        {
          __typename: 'SecurityTrainingProvider',
          id: 102,
          name: __('SecureCodeWarrior'),
          description: __('Security training with guide and learning pathways.'),
          url: 'https://www.securecodewarrior.com/',
          isEnabled: true,
        },
      ];
    },
  },
};

export const initSecurityConfiguration = (el) => {
  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(tempResolvers),
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
