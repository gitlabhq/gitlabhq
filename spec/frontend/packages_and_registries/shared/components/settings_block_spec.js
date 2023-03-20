import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';

describe('SettingsBlock', () => {
  let wrapper;

  const mountComponent = (propsData) => {
    wrapper = shallowMountExtended(SettingsBlock, {
      propsData,
      slots: {
        title: '<div data-testid="title-slot"></div>',
        description: '<div data-testid="description-slot"></div>',
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  const findDefaultSlot = () => wrapper.findByTestId('default-slot');
  const findTitleSlot = () => wrapper.findByTestId('title-slot');
  const findDescriptionSlot = () => wrapper.findByTestId('description-slot');

  it('has a default slot', () => {
    mountComponent();

    expect(findDefaultSlot().exists()).toBe(true);
  });

  it('has a title slot', () => {
    mountComponent();

    expect(findTitleSlot().exists()).toBe(true);
  });

  it('has a description slot', () => {
    mountComponent();

    expect(findDescriptionSlot().exists()).toBe(true);
  });
});
