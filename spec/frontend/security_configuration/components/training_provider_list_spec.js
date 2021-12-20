import { GlLink, GlToggle, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import TrainingProviderList from '~/security_configuration/components/training_provider_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { securityTrainingProviders, mockResolvers } from '../mock_data';

Vue.use(VueApollo);

describe('TrainingProviderList component', () => {
  let wrapper;
  let mockApollo;
  let mockSecurityTrainingProvidersData;

  const createComponent = () => {
    mockApollo = createMockApollo([], mockResolvers);

    wrapper = shallowMount(TrainingProviderList, {
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
});
