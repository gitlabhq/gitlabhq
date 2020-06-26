import { shallowMount } from '@vue/test-utils';
import component from '~/registry/explorer/components/list_item.vue';

describe('list item', () => {
  let wrapper;

  const findLeftActionSlot = () => wrapper.find('[data-testid="left-action"]');
  const findLeftPrimarySlot = () => wrapper.find('[data-testid="left-primary"]');
  const findLeftSecondarySlot = () => wrapper.find('[data-testid="left-secondary"]');
  const findRightPrimarySlot = () => wrapper.find('[data-testid="right-primary"]');
  const findRightSecondarySlot = () => wrapper.find('[data-testid="right-secondary"]');
  const findRightActionSlot = () => wrapper.find('[data-testid="right-action"]');

  const mountComponent = propsData => {
    wrapper = shallowMount(component, {
      propsData,
      slots: {
        'left-action': '<div data-testid="left-action" />',
        'left-primary': '<div data-testid="left-primary" />',
        'left-secondary': '<div data-testid="left-secondary" />',
        'right-primary': '<div data-testid="right-primary" />',
        'right-secondary': '<div data-testid="right-secondary" />',
        'right-action': '<div data-testid="right-action" />',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it.each`
    slotName             | finderFunction
    ${'left-primary'}    | ${findLeftPrimarySlot}
    ${'left-secondary'}  | ${findLeftSecondarySlot}
    ${'right-primary'}   | ${findRightPrimarySlot}
    ${'right-secondary'} | ${findRightSecondarySlot}
    ${'left-action'}     | ${findLeftActionSlot}
    ${'right-action'}    | ${findRightActionSlot}
  `('has a $slotName slot', ({ finderFunction }) => {
    mountComponent();

    expect(finderFunction().exists()).toBe(true);
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

    it('when index is not 0 hides top border', () => {
      mountComponent({ index: 1 });

      expect(wrapper.classes()).toEqual(
        expect.not.arrayContaining(['gl-border-t-solid', 'gl-border-t-1']),
      );
    });
  });

  describe('selected prop', () => {
    it('when true applies the selected border and background', () => {
      mountComponent({ selected: true });

      expect(wrapper.classes()).toEqual(
        expect.arrayContaining(['gl-bg-blue-50', 'gl-border-blue-200']),
      );
      expect(wrapper.classes()).toEqual(expect.not.arrayContaining(['gl-border-gray-200']));
    });

    it('when false applies the default border', () => {
      mountComponent({ selected: false });

      expect(wrapper.classes()).toEqual(
        expect.not.arrayContaining(['gl-bg-blue-50', 'gl-border-blue-200']),
      );
      expect(wrapper.classes()).toEqual(expect.arrayContaining(['gl-border-gray-200']));
    });
  });
});
