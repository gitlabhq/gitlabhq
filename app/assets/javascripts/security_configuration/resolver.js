import produce from 'immer';
import { __ } from '~/locale';
import securityTrainingProvidersQuery from './graphql/security_training_providers.query.graphql';

// Note: this is behind a feature flag and only a placeholder
// until the actual GraphQL fields have been added
// https://gitlab.com/gitlab-org/gi tlab/-/issues/346480
export default {
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

  Mutation: {
    configureSecurityTrainingProviders: (
      _,
      { input: { enabledProviders, primaryProvider, fullPath } },
      { cache },
    ) => {
      const sourceData = cache.readQuery({
        query: securityTrainingProvidersQuery,
        variables: {
          fullPath,
        },
      });

      const data = produce(sourceData.project, (draftData) => {
        /* eslint-disable no-param-reassign */
        draftData.securityTrainingProviders.forEach((provider) => {
          provider.isPrimary = provider.id === primaryProvider;
          provider.isEnabled =
            provider.id === primaryProvider || enabledProviders.includes(provider.id);
        });
      });

      return {
        __typename: 'configureSecurityTrainingProvidersPayload',
        securityTrainingProviders: data.securityTrainingProviders,
      };
    },
  },
};
