import { GlButton } from '@gitlab/ui';
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
  const findDetailsSlot = name => wrapper.find(`[data-testid="${name}"]`);
  const findToggleDetailsButton = () => wrapper.find(GlButton);

  const mountComponent = (propsData, slots) => {
    wrapper = shallowMount(component, {
      propsData,
      slots: {
        'left-action': '<div data-testid="left-action" />',
        'left-primary': '<div data-testid="left-primary" />',
        'left-secondary': '<div data-testid="left-secondary" />',
        'right-primary': '<div data-testid="right-primary" />',
        'right-secondary': '<div data-testid="right-secondary" />',
        'right-action': '<div data-testid="right-action" />',
        ...slots,
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

  describe.each`
    slotNames
    ${['details_foo']}
    ${['details_foo', 'details_bar']}
    ${['details_foo', 'details_bar', 'details_baz']}
  `('$slotNames details slots', ({ slotNames }) => {
    const slotMocks = slotNames.reduce((acc, current) => {
      acc[current] = `<div data-testid="${current}" />`;
      return acc;
    }, {});

    it('are visible when details is shown', async () => {
      mountComponent({}, slotMocks);

      await wrapper.vm.$nextTick();
      findToggleDetailsButton().vm.$emit('click');

      await wrapper.vm.$nextTick();
      slotNames.forEach(name => {
        expect(findDetailsSlot(name).exists()).toBe(true);
      });
    });
    it('are not visible when details are not shown', () => {
      mountComponent({}, slotMocks);

      slotNames.forEach(name => {
        expect(findDetailsSlot(name).exists()).toBe(false);
      });
    });
  });

  describe('details toggle button', () => {
    it('is visible when at least one details slot exists', async () => {
      mountComponent({}, { details_foo: '<span></span>' });
      await wrapper.vm.$nextTick();
      expect(findToggleDetailsButton().exists()).toBe(true);
    });

    it('is hidden without details slot', () => {
      mountComponent();
      expect(findToggleDetailsButton().exists()).toBe(false);
    });
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

  describe('first prop', () => {
    it('when is true displays a double top border', () => {
      mountComponent({ first: true });

      expect(wrapper.classes('gl-border-t-2')).toBe(true);
    });

    it('when is false display a single top border', () => {
      mountComponent({ first: false });

      expect(wrapper.classes('gl-border-t-1')).toBe(true);
    });
  });

  describe('last prop', () => {
    it('when is true displays a double bottom border', () => {
      mountComponent({ last: true });

      expect(wrapper.classes('gl-border-b-2')).toBe(true);
    });

    it('when is false display a single bottom border', () => {
      mountComponent({ last: false });

      expect(wrapper.classes('gl-border-b-1')).toBe(true);
    });
  });

  describe('selected prop', () => {
    it('when true applies the selected border and background', () => {
      mountComponent({ selected: true });

      expect(wrapper.classes()).toEqual(
        expect.arrayContaining(['gl-bg-blue-50', 'gl-border-blue-200']),
      );
      expect(wrapper.classes()).toEqual(expect.not.arrayContaining(['gl-border-gray-100']));
    });

    it('when false applies the default border', () => {
      mountComponent({ selected: false });

      expect(wrapper.classes()).toEqual(
        expect.not.arrayContaining(['gl-bg-blue-50', 'gl-border-blue-200']),
      );
      expect(wrapper.classes()).toEqual(expect.arrayContaining(['gl-border-gray-100']));
    });
  });
});
