import { shallowMount } from '@vue/test-utils';
import component from '~/registry/explorer/components/list_item.vue';

describe('list item', () => {
  let wrapper;

  const findLeftPrimarySlot = () => wrapper.find('[data-testid="left-primary"]');
  const findLeftSecondarySlot = () => wrapper.find('[data-testid="left-secondary"]');
  const findRightSlot = () => wrapper.find('[data-testid="right"]');

  const mountComponent = propsData => {
    wrapper = shallowMount(component, {
      propsData,
      slots: {
        'left-primary': '<div data-testid="left-primary" />',
        'left-secondary': '<div data-testid="left-secondary" />',
        right: '<div data-testid="right" />',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('has a left primary slot', () => {
    mountComponent();
    expect(findLeftPrimarySlot().exists()).toBe(true);
  });

  it('has a left secondary slot', () => {
    mountComponent();
    expect(findLeftSecondarySlot().exists()).toBe(true);
  });

  it('has a right slot', () => {
    mountComponent();
    expect(findRightSlot().exists()).toBe(true);
  });

  describe('disabled prop', () => {
    it('when true applies disabled-content class', () => {
      mountComponent({ disabled: true });
      expect(wrapper.classes('disabled-content')).toBe(true);
    });

    it('when false does not apply disabled-content class', () => {
      mountComponent({ disabled: false });
      expect(wrapper.classes('disabled-content')).toBe(false);
    });
  });

  describe('index prop', () => {
    it('when index is 0 displays a top border', () => {
      mountComponent({ index: 0 });
      expect(wrapper.classes()).toEqual(
        expect.arrayContaining(['gl-border-t-solid', 'gl-border-t-1']),
      );
    });

    it('when index is  not 0 hides top border', () => {
      mountComponent({ index: 1 });
      expect(wrapper.classes('gl-border-t-solid')).toBe(false);
      expect(wrapper.classes('gl-border-t-1')).toBe(false);
    });
  });
});
