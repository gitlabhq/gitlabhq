import * as Sentry from '@sentry/browser';
import { GlAlert, GlLink, GlToggle, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import TrainingProviderList from '~/security_configuration/components/training_provider_list.vue';
import securityTrainingProvidersQuery from '~/security_configuration/graphql/security_training_providers.query.graphql';
import configureSecurityTrainingProvidersMutation from '~/security_configuration/graphql/configure_security_training_providers.mutation.graphql';
import dismissUserCalloutMutation from '~/graphql_shared/mutations/dismiss_user_callout.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import {
  dismissUserCalloutResponse,
  dismissUserCalloutErrorResponse,
  securityTrainingProviders,
  securityTrainingProvidersResponse,
  testProjectPath,
  textProviderIds,
} from '../mock_data';

Vue.use(VueApollo);

describe('TrainingProviderList component', () => {
  let wrapper;
  let apolloProvider;

  const createApolloProvider = ({ resolvers, handlers = [] } = {}) => {
    const defaultHandlers = [
      [
        securityTrainingProvidersQuery,
        jest.fn().mockResolvedValue(securityTrainingProvidersResponse),
      ],
    ];

    // make sure we don't have any duplicate handlers to avoid 'Request handler already defined for query` errors
    const mergedHandlers = [...new Map([...defaultHandlers, ...handlers])];

    apolloProvider = createMockApollo(mergedHandlers, resolvers);
  };

  const createComponent = () => {
    wrapper = shallowMount(TrainingProviderList, {
      provide: {
        projectFullPath: testProjectPath,
      },
      apolloProvider,
    });
  };

  const waitForQueryToBeLoaded = () => waitForPromises();
  const waitForMutationToBeLoaded = waitForQueryToBeLoaded;

  const findCards = () => wrapper.findAllComponents(GlCard);
  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findToggles = () => wrapper.findAllComponents(GlToggle);
  const findFirstToggle = () => findToggles().at(0);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  const toggleFirstProvider = () => findFirstToggle().vm.$emit('change');

  afterEach(() => {
    wrapper.destroy();
    apolloProvider = null;
  });

  describe('when loading', () => {
    beforeEach(() => {
      const pendingHandler = () => new Promise(() => {});

      createApolloProvider({
        handlers: [[securityTrainingProvidersQuery, pendingHandler]],
      });
      createComponent();
    });

    it('shows the loader', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('does not show the cards', () => {
      expect(findCards().exists()).toBe(false);
    });
  });

  describe('with a successful response', () => {
    beforeEach(() => {
      createApolloProvider({
        handlers: [
          [dismissUserCalloutMutation, jest.fn().mockResolvedValue(dismissUserCalloutResponse)],
        ],
        resolvers: {
          Mutation: {
            configureSecurityTrainingProviders: () => ({
              errors: [],
              securityTrainingProviders: [],
            }),
          },
        },
      });

      createComponent();
    });

    describe('basic structure', () => {
      beforeEach(async () => {
        await waitForQueryToBeLoaded();
      });

      it('renders correct amount of cards', () => {
        expect(findCards()).toHaveLength(securityTrainingProviders.length);
      });

      securityTrainingProviders.forEach(({ name, description, url, isEnabled }, index) => {
        it(`shows the name for card ${index}`, () => {
          expect(findCards().at(index).text()).toContain(name);
        });

        it(`shows the description for card ${index}`, () => {
          expect(findCards().at(index).text()).toContain(description);
        });

        it(`shows the learn more link for card ${index}`, () => {
          expect(findLinks().at(index).attributes()).toEqual({
            target: '_blank',
            href: url,
          });
        });

        it(`shows the toggle with the correct value for card ${index}`, () => {
          expect(findToggles().at(index).props('value')).toEqual(isEnabled);
        });

        it('does not show loader when query is populated', () => {
          expect(findLoader().exists()).toBe(false);
        });
      });
    });

    describe('storing training provider settings', () => {
      beforeEach(async () => {
        jest.spyOn(apolloProvider.defaultClient, 'mutate');

        await waitForMutationToBeLoaded();

        toggleFirstProvider();
      });

      it.each`
        loading  | wait     | desc
        ${true}  | ${false} | ${'enables loading of GlToggle when mutation is called'}
        ${false} | ${true}  | ${'disables loading of GlToggle when mutation is complete'}
      `('$desc', async ({ loading, wait }) => {
        if (wait) {
          await waitForMutationToBeLoaded();
        }
        expect(findFirstToggle().props('isLoading')).toBe(loading);
      });

      it('calls mutation when toggle is changed', () => {
        expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: configureSecurityTrainingProvidersMutation,
            variables: { input: { enabledProviders: textProviderIds, fullPath: testProjectPath } },
          }),
        );
      });

      it('dismisses the callout when the feature gets first enabled', async () => {
        // wait for configuration update mutation to complete
        await waitForMutationToBeLoaded();

        // both the config and dismiss mutations have been called
        expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledTimes(2);
        expect(apolloProvider.defaultClient.mutate).toHaveBeenNthCalledWith(
          2,
          expect.objectContaining({
            mutation: dismissUserCalloutMutation,
            variables: {
              input: {
                featureName: 'security_training_feature_promotion',
              },
            },
          }),
        );

        toggleFirstProvider();
        await waitForMutationToBeLoaded();

        // the config mutation has been called again but not the dismiss mutation
        expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledTimes(3);
        expect(apolloProvider.defaultClient.mutate).toHaveBeenNthCalledWith(
          3,
          expect.objectContaining({
            mutation: configureSecurityTrainingProvidersMutation,
          }),
        );
      });
    });
  });

  describe('with errors', () => {
    const expectErrorAlertToExist = () => {
      expect(findErrorAlert().props()).toMatchObject({
        dismissible: false,
        variant: 'danger',
      });
    };

    describe('when fetching training providers', () => {
      beforeEach(async () => {
        createApolloProvider({
          handlers: [[securityTrainingProvidersQuery, jest.fn().mockRejectedValue()]],
        });
        createComponent();

        await waitForQueryToBeLoaded();
      });

      it('shows an non-dismissible error alert', () => {
        expectErrorAlertToExist();
      });

      it('shows an error description', () => {
        expect(findErrorAlert().text()).toBe(TrainingProviderList.i18n.providerQueryErrorMessage);
      });
    });

    describe('when storing training provider configurations', () => {
      beforeEach(async () => {
        createApolloProvider({
          resolvers: {
            Mutation: {
              configureSecurityTrainingProviders: () => ({
                errors: ['something went wrong!'],
                securityTrainingProviders: [],
              }),
            },
          },
        });
        createComponent();

        await waitForQueryToBeLoaded();
        toggleFirstProvider();
        await waitForMutationToBeLoaded();
      });

      it('shows an non-dismissible error alert', () => {
        expectErrorAlertToExist();
      });

      it('shows an error description', () => {
        expect(findErrorAlert().text()).toBe(TrainingProviderList.i18n.configMutationErrorMessage);
      });
    });

    describe.each`
      errorType          | mutationHandler
      ${'backend error'} | ${jest.fn().mockReturnValue(dismissUserCalloutErrorResponse)}
      ${'network error'} | ${jest.fn().mockRejectedValue()}
    `('when dismissing the callout and a "$errorType" happens', ({ mutationHandler }) => {
      beforeEach(async () => {
        jest.spyOn(Sentry, 'captureException').mockImplementation();

        createApolloProvider({
          handlers: [[dismissUserCalloutMutation, mutationHandler]],
          resolvers: {
            Mutation: {
              configureSecurityTrainingProviders: () => ({
                errors: [],
                securityTrainingProviders: [],
              }),
            },
          },
        });
        createComponent();

        await waitForQueryToBeLoaded();
        toggleFirstProvider();
      });

      it('logs the error to sentry', async () => {
        expect(Sentry.captureException).not.toHaveBeenCalled();

        await waitForMutationToBeLoaded();

        expect(Sentry.captureException).toHaveBeenCalled();
      });
    });
  });
});
