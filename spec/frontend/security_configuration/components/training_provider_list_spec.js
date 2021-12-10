import { GlLink, GlToggle, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TrainingProviderList from '~/security_configuration/components/training_provider_list.vue';
import { securityTrainingProviders } from '../mock_data';

const DEFAULT_PROPS = {
  providers: securityTrainingProviders,
};

describe('TrainingProviderList component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TrainingProviderList, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

  const findCards = () => wrapper.findAllComponents(GlCard);
  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findToggles = () => wrapper.findAllComponents(GlToggle);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('basic structure', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders correct amount of cards', () => {
      expect(findCards()).toHaveLength(DEFAULT_PROPS.providers.length);
    });

    DEFAULT_PROPS.providers.forEach(({ name, description, url, isEnabled }, index) => {
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
    });
  });

  describe('loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('shows the loader', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('does not show the cards', () => {
      expect(findCards().exists()).toBe(false);
    });

    it('does not show loader when not loading', () => {
      createComponent({ loading: false });
      expect(findLoader().exists()).toBe(false);
    });
  });
});
