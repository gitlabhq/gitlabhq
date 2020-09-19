import { shallowMount } from '@vue/test-utils';
import TerminalControls from '~/ide/components/terminal/terminal_controls.vue';
import ScrollButton from '~/ide/components/jobs/detail/scroll_button.vue';

describe('IDE TerminalControls', () => {
  let wrapper;
  let buttons;

  const factory = (options = {}) => {
    wrapper = shallowMount(TerminalControls, {
      ...options,
    });

    buttons = wrapper.findAll(ScrollButton);
  };

  it('shows an up and down scroll button', () => {
    factory();

    expect(buttons.wrappers.map(x => x.props())).toEqual([
      expect.objectContaining({ direction: 'up', disabled: true }),
      expect.objectContaining({ direction: 'down', disabled: true }),
    ]);
  });

  it('enables up button with prop', () => {
    factory({ propsData: { canScrollUp: true } });

    expect(buttons.at(0).props()).toEqual(
      expect.objectContaining({ direction: 'up', disabled: false }),
    );
  });

  it('enables down button with prop', () => {
    factory({ propsData: { canScrollDown: true } });

    expect(buttons.at(1).props()).toEqual(
      expect.objectContaining({ direction: 'down', disabled: false }),
    );
  });

  it('emits "scroll-up" when click up button', () => {
    factory({ propsData: { canScrollUp: true } });

    expect(wrapper.emitted()).toEqual({});

    buttons.at(0).vm.$emit('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('scroll-up')).toEqual([[]]);
    });
  });

  it('emits "scroll-down" when click down button', () => {
    factory({ propsData: { canScrollDown: true } });

    expect(wrapper.emitted()).toEqual({});

    buttons.at(1).vm.$emit('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('scroll-down')).toEqual([[]]);
    });
  });
});
