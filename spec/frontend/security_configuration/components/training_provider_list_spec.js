import { GlLink, GlToggle, GlCard } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TrainingProviderList from '~/security_configuration/components/training_provider_list.vue';
import { TRAINING_PROVIDERS } from '~/security_configuration/components/app.vue';

const DEFAULT_PROPS = {
  providers: TRAINING_PROVIDERS,
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
});
