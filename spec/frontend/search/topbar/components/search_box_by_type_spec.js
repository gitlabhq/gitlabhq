//
// this component test should be here only temporary until this MR gets sorted:
// https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/3969
//
import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import ClearIcon from '~/search/topbar/components/clear_icon_button.vue';
import SearchBoxByType from '~/search/topbar/components/search_box_by_type.vue';

const modelEvent = SearchBoxByType.model.event;
const newValue = 'new value';

describe('search box by type component', () => {
  let wrapper;

  const createComponent = ({ listeners, ...propsData }, mountFn = shallowMount) => {
    wrapper = mountFn(SearchBoxByType, { propsData, listeners });
  };

  const findClearIcon = () => wrapper.findComponent(ClearIcon);
  const findInput = () => wrapper.findComponent({ ref: 'input' });
  const findRegulareExpressionToggle = () =>
    wrapper.findComponent('[data-testid="reqular-expression-toggle"]');

  describe('borderless', () => {
    it('renders default class on input when `borderless` prop is false', () => {
      createComponent({ borderless: false });

      expect(findInput().classes()).toContain('gl-search-box-by-type-input');
    });

    it('renders borderless class on input when `borderless` prop is true', () => {
      createComponent({ borderless: true });

      expect(findInput().classes()).toContain('gl-search-box-by-type-input-borderless');
    });
  });

  describe('clear icon component', () => {
    beforeEach(() => {
      createComponent({ value: 'somevalue' });
    });

    it('is not rendered when value is empty', () => {
      createComponent({ value: '' });

      expect(findClearIcon().exists()).toBe(false);
    });

    it('is not rendered when it is disabled', () => {
      createComponent({ disabled: true, value: 'somevalue' });

      expect(findClearIcon().exists()).toBe(false);
    });

    it('is rendered when value is provided', () => {
      expect(findClearIcon().exists()).toBe(true);
    });

    it('emits empty value when clicked', () => {
      findClearIcon().vm.$emit('click', { stopPropagation: jest.fn() });

      expect(wrapper.emitted('input')).toEqual([['']]);
    });

    it('emits `focusin` event when focus inside the component', () => {
      findInput().vm.$emit('focusin', { preventDefault: jest.fn() });

      expect(wrapper.emitted('focus')).toBe(undefined);
      expect(wrapper.emitted('focusin')).toHaveLength(1);
    });
    it('emits `focusout` event when focus moves outside the component', () => {
      findInput().vm.$emit('focusout', { preventDefault: jest.fn() });
      expect(wrapper.emitted('blur')).toBe(undefined);

      expect(wrapper.emitted('focusout')).toHaveLength(1);
    });

    it('does NOT emit `focusout` event when tabbing inside the component back and forth', () => {
      findInput().vm.$emit('focusout', {
        preventDefault: jest.fn(),
        relatedTarget: wrapper.vm.$refs.input.$el,
      });
      findClearIcon().vm.$emit('focusout', {
        preventDefault: jest.fn(),
        relatedTarget: wrapper.vm.$refs.clearButton.$el,
      });

      expect(wrapper.emitted('focusout')).toBe(undefined);
    });
  });

  describe('v-model', () => {
    beforeEach(() => {
      createComponent({ value: 'somevalue' }, mount);
    });

    it('syncs value prop to input value', async () => {
      wrapper.setProps({ value: newValue });
      await nextTick();

      expect(findInput().element.value).toEqual(newValue);
    });

    it(`emits ${modelEvent} event when input value changes`, () => {
      findInput().setValue(newValue);

      expect(wrapper.emitted('input')).toEqual([[newValue]]);
    });
  });

  // Regression test for https://gitlab.com/gitlab-org/gitlab-ui/-/issues/937
  describe('double input event bug', () => {
    let listener;

    beforeEach(() => {
      listener = jest.fn();
      createComponent({ listeners: { input: listener } }, mount);
      findInput().setValue(newValue);
    });

    it('only calls the listener once', () => {
      expect(listener.mock.calls).toEqual([[newValue]]);
    });
  });

  describe('debounce', () => {
    describe.each([10, 100, 1000])('given a debounce of %dms', (debounce) => {
      beforeEach(() => {
        jest.useFakeTimers();

        createComponent({ debounce }, mount);

        findInput().setValue(newValue);
      });

      it(`emits a ${modelEvent} after the debounce delay`, () => {
        // Just before debounce completes
        jest.advanceTimersByTime(debounce - 1);
        expect(wrapper.emitted(modelEvent)).toBe(undefined);
        // Exactly when debounce completes
        jest.advanceTimersByTime(1);

        expect(wrapper.emitted(modelEvent)).toEqual([[newValue]]);
      });
    });
  });

  describe('lazy', () => {
    beforeEach(() => {
      createComponent({ lazy: true }, mount);

      findInput().setValue(newValue);
    });

    it.each(['change', 'blur'])(`emits ${modelEvent} event after input's %s event`, (event) => {
      expect(wrapper.emitted(modelEvent)).toBe(undefined);

      findInput().trigger(event);

      expect(wrapper.emitted(modelEvent)).toEqual([[newValue]]);
    });
  });

  it('renders loading icon when `isLoading` prop is provided', () => {
    createComponent({ isLoading: true });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  describe('regular expression button', () => {
    const regexButtonHandlerSpy = jest.fn();
    beforeEach(() => {
      createComponent({
        regexButtonIsVisible: true,
        regexButtonState: true,
        regexButtonHandler: regexButtonHandlerSpy,
      });
    });

    it('renders regular expression button', () => {
      expect(findRegulareExpressionToggle().exists()).toBe(true);
    });

    it('renders regular expression button state correctly', () => {
      expect(findRegulareExpressionToggle().classes('!gl-bg-blue-50')).toBe(true);
    });

    it('triggers correct action when clicked', () => {
      findRegulareExpressionToggle().vm.$emit('click');

      expect(regexButtonHandlerSpy).toHaveBeenCalled();
    });
  });
});
