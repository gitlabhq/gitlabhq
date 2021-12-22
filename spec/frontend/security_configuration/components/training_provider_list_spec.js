import { GlLink, GlToggle, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import TrainingProviderList from '~/security_configuration/components/training_provider_list.vue';
import configureSecurityTrainingProvidersMutation from '~/security_configuration/graphql/configure_security_training_providers.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import {
  securityTrainingProviders,
  mockResolvers,
  testProjectPath,
  textProviderIds,
} from '../mock_data';

Vue.use(VueApollo);

describe('TrainingProviderList component', () => {
  let wrapper;
  let mockApollo;
  let mockSecurityTrainingProvidersData;

  const createComponent = () => {
    mockApollo = createMockApollo([], mockResolvers);

    wrapper = shallowMount(TrainingProviderList, {
      provide: {
        projectPath: testProjectPath,
      },
      apolloProvider: mockApollo,
    });
  };

  const waitForQueryToBeLoaded = () => waitForPromises();

  const findCards = () => wrapper.findAllComponents(GlCard);
  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findToggles = () => wrapper.findAllComponents(GlToggle);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);

  beforeEach(() => {
    mockSecurityTrainingProvidersData = jest.fn();
    mockSecurityTrainingProvidersData.mockResolvedValue(securityTrainingProviders);

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    mockApollo = null;
  });

  describe('when loading', () => {
    it('shows the loader', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('does not show the cards', () => {
      expect(findCards().exists()).toBe(false);
    });
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

  describe('success mutation', () => {
    const firstToggle = () => findToggles().at(0);

    beforeEach(async () => {
      jest.spyOn(mockApollo.defaultClient, 'mutate');

      await waitForQueryToBeLoaded();

      firstToggle().vm.$emit('change');
    });

    it('calls mutation when toggle is changed', () => {
      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith(
        expect.objectContaining({
          mutation: configureSecurityTrainingProvidersMutation,
          variables: { input: { enabledProviders: textProviderIds, fullPath: testProjectPath } },
        }),
      );
    });

    it.each`
      loading  | wait     | desc
      ${true}  | ${false} | ${'enables loading of GlToggle when mutation is called'}
      ${false} | ${true}  | ${'disables loading of GlToggle when mutation is complete'}
    `('$desc', async ({ loading, wait }) => {
      if (wait) {
        await waitForPromises();
      }
      expect(firstToggle().props('isLoading')).toBe(loading);
    });
  });
});
