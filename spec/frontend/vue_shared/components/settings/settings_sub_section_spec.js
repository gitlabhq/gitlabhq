import { mountExtended } from 'helpers/vue_test_utils_helper';
import SettingsSubSection from '~/vue_shared/components/settings/settings_sub_section.vue';

describe('Settings Sub Section', () => {
  let wrapper;

  const mountComponent = (propsData) => {
    wrapper = mountExtended(SettingsSubSection, {
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
  const findHeading = () => wrapper.findByTestId('settings-sub-section-heading');
  const findDescriptionSlot = () => wrapper.findByTestId('description-slot');
  const findDescription = () => wrapper.findByTestId('settings-sub-section-description');

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
    expect(findHeading().classes()).toEqual(['gl-heading-3', '!gl-mb-3']);
  });

  it('has a description slot', () => {
    mountComponent();

    expect(findDescriptionSlot().exists()).toBe(true);
  });

  it('has correct description text and classes', () => {
    mountComponent();

    expect(findDescription().text()).toBe('Description');
    expect(findDescription().classes()).toEqual(expect.arrayContaining(['gl-text-subtle']));
  });
});
