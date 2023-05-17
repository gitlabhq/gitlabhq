import { GlDropdown, GlDropdownDivider, GlButton, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ActionsButton from '~/vue_shared/components/actions_button.vue';

const TEST_ACTION = {
  key: 'action1',
  text: 'Sample',
  secondaryText: 'Lorem ipsum.',
  tooltip: '',
  href: '/sample',
  attrs: {
    'data-test': '123',
    category: 'secondary',
    href: '/sample',
    variant: 'default',
  },
};
const TEST_ACTION_2 = {
  key: 'action2',
  text: 'Sample 2',
  secondaryText: 'Dolar sit amit.',
  tooltip: 'Dolar sit amit.',
  href: '#',
  attrs: { 'data-test': '456' },
};
const TEST_TOOLTIP = 'Lorem ipsum dolar sit';

describe('Actions button component', () => {
  let wrapper;

  function createComponent(props) {
    wrapper = shallowMount(ActionsButton, {
      propsData: { ...props },
    });
  }

  const findButton = () => wrapper.findComponent(GlButton);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const parseDropdownItems = () =>
    findDropdown()
      .findAll('gl-dropdown-item-stub,gl-dropdown-divider-stub')
      .wrappers.map((x) => {
        if (x.is(GlDropdownDivider)) {
          return { type: 'divider' };
        }

        const { isCheckItem, isChecked, secondaryText } = x.props();

        return {
          type: 'item',
          isCheckItem,
          isChecked,
          secondaryText,
          text: x.text(),
        };
      });
  const clickOn = (child, evt = new Event('click')) => child.vm.$emit('click', evt);
  const clickLink = (...args) => clickOn(findButton(), ...args);
  const clickDropdown = (...args) => clickOn(findDropdown(), ...args);

  describe('with 1 action', () => {
    beforeEach(() => {
      createComponent({ actions: [TEST_ACTION] });
    });

    it('should not render dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
    });

    it('should render single button', () => {
      expect(findButton().attributes()).toMatchObject({
        href: TEST_ACTION.href,
        ...TEST_ACTION.attrs,
      });
      expect(findButton().text()).toBe(TEST_ACTION.text);
    });

    it('should not have tooltip', () => {
      expect(findTooltip().exists()).toBe(false);
    });

    it('should have attrs', () => {
      expect(findButton().attributes()).toMatchObject(TEST_ACTION.attrs);
    });

    it('can click', () => {
      expect(clickLink).not.toThrow();
    });
  });

  describe('with 1 action with tooltip', () => {
    it('should have tooltip', () => {
      createComponent({ actions: [{ ...TEST_ACTION, tooltip: TEST_TOOLTIP }] });

      expect(findTooltip().text()).toBe(TEST_TOOLTIP);
    });
  });

  describe('when showActionTooltip is false', () => {
    it('should not have tooltip', () => {
      createComponent({
        actions: [{ ...TEST_ACTION, tooltip: TEST_TOOLTIP }],
        showActionTooltip: false,
      });

      expect(findTooltip().exists()).toBe(false);
    });
  });

  describe('with 1 action with handle', () => {
    it('can click and trigger handle', () => {
      const handleClick = jest.fn();
      createComponent({ actions: [{ ...TEST_ACTION, handle: handleClick }] });

      const event = new Event('click');
      clickLink(event);

      expect(handleClick).toHaveBeenCalledWith(event);
    });
  });

  describe('with multiple actions', () => {
    let handleAction;

    beforeEach(() => {
      handleAction = jest.fn();

      createComponent({ actions: [{ ...TEST_ACTION, handle: handleAction }, TEST_ACTION_2] });
    });

    it('should default to selecting first action', () => {
      expect(findDropdown().attributes()).toMatchObject({
        text: TEST_ACTION.text,
        'split-href': TEST_ACTION.href,
      });
    });

    it('should handle first action click', () => {
      const event = new Event('click');

      clickDropdown(event);

      expect(handleAction).toHaveBeenCalledWith(event);
    });

    it('should render dropdown items', () => {
      expect(parseDropdownItems()).toEqual([
        {
          type: 'item',
          isCheckItem: true,
          isChecked: true,
          secondaryText: TEST_ACTION.secondaryText,
          text: TEST_ACTION.text,
        },
        { type: 'divider' },
        {
          type: 'item',
          isCheckItem: true,
          isChecked: false,
          secondaryText: TEST_ACTION_2.secondaryText,
          text: TEST_ACTION_2.text,
        },
      ]);
    });

    it('should select action 2 when clicked', () => {
      expect(wrapper.emitted('select')).toBeUndefined();

      const action2 = wrapper.find(`[data-testid="action_${TEST_ACTION_2.key}"]`);
      action2.vm.$emit('click');

      expect(wrapper.emitted('select')).toEqual([[TEST_ACTION_2.key]]);
    });

    it('should not have tooltip value', () => {
      expect(findTooltip().exists()).toBe(false);
    });
  });

  describe('with multiple actions and selectedKey', () => {
    beforeEach(() => {
      createComponent({ actions: [TEST_ACTION, TEST_ACTION_2], selectedKey: TEST_ACTION_2.key });
    });

    it('should show action 2 as selected', () => {
      expect(parseDropdownItems()).toEqual([
        expect.objectContaining({
          type: 'item',
          isChecked: false,
        }),
        { type: 'divider' },
        expect.objectContaining({
          type: 'item',
          isChecked: true,
        }),
      ]);
    });

    it('should have tooltip value', () => {
      expect(findTooltip().text()).toBe(TEST_ACTION_2.tooltip);
    });
  });
});
