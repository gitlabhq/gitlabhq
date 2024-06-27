import { mountExtended } from 'helpers/vue_test_utils_helper';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';

describe('Settings Block', () => {
  let wrapper;

  const mountComponent = (propsData) => {
    wrapper = mountExtended(SettingsSection, {
      propsData,
      slots: {
        heading: '<div data-testid="heading-slot">Advanced</div>',
        description: '<div data-testid="description-slot"></div>',
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  const findDefaultSlot = () => wrapper.findByTestId('default-slot');
  const findHeadingSlot = () => wrapper.findByTestId('heading-slot');
  const findDescriptionSlot = () => wrapper.findByTestId('description-slot');

  it('has a default slot', () => {
    mountComponent();

    expect(findDefaultSlot().exists()).toBe(true);
  });

  it('has a heading slot', () => {
    mountComponent();

    expect(findHeadingSlot().exists()).toBe(true);
  });

  it('has a description slot', () => {
    mountComponent();

    expect(findDescriptionSlot().exists()).toBe(true);
  });
});
