import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';

describe('Toggle Button component', () => {
  let wrapper;

  function createComponent(propsData = {}) {
    wrapper = shallowMount(ToggleButton, {
      propsData,
    });
  }

  const findInput = () => wrapper.find('input');
  const findButton = () => wrapper.find('button');
  const findToggleIcon = () => wrapper.find(GlIcon);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders input with provided name', () => {
    createComponent({
      name: 'foo',
    });

    expect(findInput().attributes('name')).toBe('foo');
  });

  describe.each`
    value    | iconName
    ${true}  | ${'status_success_borderless'}
    ${false} | ${'status_failed_borderless'}
  `('when `value` prop is `$value`', ({ value, iconName }) => {
    beforeEach(() => {
      createComponent({
        value,
        name: 'foo',
      });
    });

    it('renders input with correct value attribute', () => {
      expect(findInput().attributes('value')).toBe(`${value}`);
    });

    it('renders correct icon', () => {
      const icon = findToggleIcon();
      expect(icon.isVisible()).toBe(true);
      expect(icon.props('name')).toBe(iconName);
      expect(findButton().classes('is-checked')).toBe(value);
    });

    describe('when clicked', () => {
      it('emits `change` event with correct event', async () => {
        findButton().trigger('click');
        await wrapper.vm.$nextTick();

        expect(wrapper.emitted('change')).toStrictEqual([[!value]]);
      });
    });
  });

  describe('when `disabledInput` prop is `true`', () => {
    beforeEach(() => {
      createComponent({
        value: true,
        disabledInput: true,
      });
    });

    it('renders disabled button', () => {
      expect(findButton().classes()).toContain('is-disabled');
    });

    it('does not emit change event when clicked', async () => {
      findButton().trigger('click');
      await wrapper.vm.$nextTick();

      expect(wrapper.emitted('change')).toBeFalsy();
    });
  });

  describe('when `isLoading` prop is `true`', () => {
    beforeEach(() => {
      createComponent({
        value: true,
        isLoading: true,
      });
    });

    it('renders loading class', () => {
      expect(findButton().classes()).toContain('is-loading');
    });
  });
});
