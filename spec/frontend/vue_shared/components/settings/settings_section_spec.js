import { mountExtended } from 'helpers/vue_test_utils_helper';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';

describe('Settings Block', () => {
  let wrapper;

  const mountComponent = (propsData) => {
    wrapper = mountExtended(SettingsSection, {
      propsData,
      slots: {
        heading: '<div data-testid="heading-slot">Heading</div>',
        description: '<div data-testid="description-slot">Description</div>',
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  const findDefaultSlot = () => wrapper.findByTestId('default-slot');
  const findHeadingSlot = () => wrapper.findByTestId('heading-slot');
  const findHeading = () => wrapper.findByTestId('settings-section-heading');
  const findDescriptionSlot = () => wrapper.findByTestId('description-slot');
  const findDescription = () => wrapper.findByTestId('settings-section-description');

  it('has a default slot', () => {
    mountComponent();

    expect(findDefaultSlot().exists()).toBe(true);
  });

  it('has a heading slot', () => {
    mountComponent();

    expect(findHeadingSlot().exists()).toBe(true);
  });

  it('has correct heading text and classes', () => {
    mountComponent();

    expect(findHeading().text()).toBe('Heading');
    expect(findHeading().classes()).toEqual(['gl-heading-2', '!gl-mb-3']);
  });

  it('has a description slot', () => {
    mountComponent();

    expect(findDescriptionSlot().exists()).toBe(true);
  });

  it('has correct description text and classes', () => {
    mountComponent();

    expect(findDescription().text()).toBe('Description');
    expect(findDescription().classes()).toEqual(
      expect.arrayContaining(['gl-text-subtle', 'gl-mb-3']),
    );
  });
});
