import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import component from '~/vue_shared/components/usage_quotas/usage_banner.vue';

describe('usage banner', () => {
  let wrapper;

  const findLeftPrimaryTextSlot = () => wrapper.findByTestId('left-primary-text');
  const findLeftSecondaryTextSlot = () => wrapper.findByTestId('left-secondary-text');
  const findRightPrimaryTextSlot = () => wrapper.findByTestId('right-primary-text');
  const findRightSecondaryTextSlot = () => wrapper.findByTestId('right-secondary-text');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const mountComponent = (propsData, slots) => {
    wrapper = shallowMountExtended(component, {
      propsData,
      slots: {
        'left-primary-text': '<div data-testid="left-primary-text" />',
        'left-secondary-text': '<div data-testid="left-secondary-text" />',
        'right-primary-text': '<div data-testid="right-primary-text" />',
        'right-secondary-text': '<div data-testid="right-secondary-text" />',
        ...slots,
      },
    });
  };

  describe.each`
    slotName                  | finderFunction
    ${'left-primary-text'}    | ${findLeftPrimaryTextSlot}
    ${'left-secondary-text'}  | ${findLeftSecondaryTextSlot}
    ${'right-primary-text'}   | ${findRightPrimaryTextSlot}
    ${'right-secondary-text'} | ${findRightSecondaryTextSlot}
  `('$slotName slot', ({ finderFunction, slotName }) => {
    it('exist when the slot is filled', () => {
      mountComponent();

      expect(finderFunction().exists()).toBe(true);
    });

    it('does not exist when the slot is empty', () => {
      mountComponent({}, { [slotName]: '' });

      expect(finderFunction().exists()).toBe(false);
    });
  });

  it('should show a skeleton loader component', () => {
    mountComponent({ loading: true });

    expect(findSkeletonLoader().exists()).toBe(true);
  });

  it('should not show a skeleton loader component', () => {
    mountComponent();

    expect(findSkeletonLoader().exists()).toBe(false);
  });
});
