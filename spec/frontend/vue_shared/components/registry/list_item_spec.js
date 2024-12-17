import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import component from '~/vue_shared/components/registry/list_item.vue';

describe('list item', () => {
  let wrapper;

  const findLeftActionSlot = () => wrapper.find('[data-testid="left-action"]');
  const findLeftPrimarySlot = () => wrapper.find('[data-testid="left-primary"]');
  const findLeftSecondarySlot = () => wrapper.find('[data-testid="left-secondary"]');
  const findLeftAfterToggleSlot = () => wrapper.find('[data-testid="left-after-toggle"]');
  const findRightPrimarySlot = () => wrapper.find('[data-testid="right-primary"]');
  const findRightSecondarySlot = () => wrapper.find('[data-testid="right-secondary"]');
  const findRightActionSlot = () => wrapper.find('[data-testid="right-action"]');
  const findDetailsSlot = (name) => wrapper.find(`[data-testid="${name}"]`);
  const findToggleDetailsButton = () => wrapper.findComponent(GlButton);

  const mountComponent = (propsData, slots) => {
    wrapper = shallowMount(component, {
      propsData,
      slots: {
        'left-action': '<div data-testid="left-action" />',
        'left-primary': '<div data-testid="left-primary" />',
        'left-secondary': '<div data-testid="left-secondary" />',
        'left-after-toggle': '<div data-testid="left-after-toggle" />',
        'right-primary': '<div data-testid="right-primary" />',
        'right-secondary': '<div data-testid="right-secondary" />',
        'right-action': '<div data-testid="right-action" />',
        ...slots,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe.each`
    slotName               | finderFunction
    ${'left-primary'}      | ${findLeftPrimarySlot}
    ${'left-secondary'}    | ${findLeftSecondarySlot}
    ${'left-after-toggle'} | ${findLeftAfterToggleSlot}
    ${'right-primary'}     | ${findRightPrimarySlot}
    ${'right-secondary'}   | ${findRightSecondarySlot}
    ${'left-action'}       | ${findLeftActionSlot}
    ${'right-action'}      | ${findRightActionSlot}
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

  describe.each`
    slotNames
    ${['details-foo']}
    ${['details-foo', 'details-bar']}
    ${['details-foo', 'details-bar', 'details-baz']}
  `('$slotNames details slots', ({ slotNames }) => {
    const slotMocks = slotNames.reduce((acc, current) => {
      acc[current] = `<div data-testid="${current}" />`;
      return acc;
    }, {});

    it('are visible when details is shown', async () => {
      mountComponent({}, slotMocks);

      await nextTick();
      findToggleDetailsButton().vm.$emit('click');

      await nextTick();
      slotNames.forEach((name) => {
        expect(findDetailsSlot(name).exists()).toBe(true);
      });
    });
    it('are not visible when details are not shown', () => {
      mountComponent({}, slotMocks);

      slotNames.forEach((name) => {
        expect(findDetailsSlot(name).exists()).toBe(false);
      });
    });
  });

  describe('details toggle button', () => {
    it('is visible when at least one details slot exists', async () => {
      mountComponent({}, { 'details-foo': '<span></span>' });
      await nextTick();
      expect(findToggleDetailsButton().exists()).toBe(true);
    });

    describe('when visible', () => {
      beforeEach(async () => {
        mountComponent({}, { 'details-foo': '<span></span>' });
        await nextTick();
      });

      it('has tooltip', () => {
        const tooltip = getBinding(findToggleDetailsButton().element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(findToggleDetailsButton().attributes('title')).toBe('Show details');
      });

      it('has correct attributes and props', () => {
        expect(findToggleDetailsButton().attributes()).toMatchObject({
          'aria-label': 'Show details',
          icon: 'chevron-down',
          title: 'Show details',
        });
      });

      it('has correct attributes and props when clicked', async () => {
        findToggleDetailsButton().vm.$emit('click');
        await nextTick();

        expect(findToggleDetailsButton().attributes()).toMatchObject({
          'aria-expanded': 'true',
          'aria-label': 'Hide details',
          icon: 'chevron-up',
          title: 'Hide details',
        });
      });
    });

    it('is hidden without details slot', () => {
      mountComponent();
      expect(findToggleDetailsButton().exists()).toBe(false);
    });
  });

  describe('borders and selection', () => {
    it.each`
      first    | selected | shouldHave                                 | shouldNotHave
      ${true}  | ${true}  | ${['gl-bg-blue-50', 'gl-border-blue-200']} | ${['gl-border-t-transparent', 'gl-border-t-default']}
      ${false} | ${true}  | ${['gl-bg-blue-50', 'gl-border-blue-200']} | ${['gl-border-t-transparent', 'gl-border-t-default']}
      ${true}  | ${false} | ${['gl-border-b-default']}                 | ${['gl-bg-blue-50', 'gl-border-blue-200']}
      ${false} | ${false} | ${['gl-border-b-default']}                 | ${['gl-bg-blue-50', 'gl-border-blue-200']}
    `(
      'when first is $first and selected is $selected',
      ({ first, selected, shouldHave, shouldNotHave }) => {
        mountComponent({ first, selected });

        expect(wrapper.classes()).toEqual(expect.arrayContaining(shouldHave));

        expect(wrapper.classes()).toEqual(expect.not.arrayContaining(shouldNotHave));
      },
    );
  });
});
