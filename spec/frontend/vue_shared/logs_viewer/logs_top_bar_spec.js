import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LogsTopBar from '~/vue_shared/components/logs_viewer/logs_top_bar.vue';

describe('logs_top_bar.vue', () => {
  let wrapper;

  const defaultSlots = {
    default: '<b>slot value</b>',
  };

  const createWrapper = ({ propsData = {}, slots = defaultSlots } = {}) => {
    wrapper = shallowMountExtended(LogsTopBar, {
      propsData,
      slots,
    });
  };

  const findButtons = () => wrapper.findAllComponents(GlButton);
  const findButton = (at) => findButtons().at(at);

  describe('by default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it.each([
      ['scroll_down', 'Scroll to bottom', 0],
      ['scroll_up', 'Scroll to top', 1],
      ['maximize', 'Enter full screen', 2],
    ])('renders %s button with the correct props', (icon, label, index) => {
      expect(findButton(index).props('icon')).toBe(icon);
      expect(findButton(index).props('selected')).toBe(false);
      expect(findButton(index).attributes('title')).toBe(label);
      expect(findButton(index).attributes('aria-label')).toBe(label);
    });

    it.each([
      ['scrollToBottom', 'scroll_down', 0],
      ['scrollToTop', 'scroll_up', 1],
      ['toggleFullScreen', 'maximize', 2],
    ])('emits %s event when user clicks on %s button', (event, button, index) => {
      expect(wrapper.emitted(event)).toBeUndefined();
      findButton(index).vm.$emit('click');

      expect(wrapper.emitted(event)).toHaveLength(1);
    });

    it('renders default slot content', () => {
      expect(wrapper.html()).toContain(defaultSlots.default);
    });
  });

  describe('when isFullScreen prop is provided', () => {
    beforeEach(() => {
      createWrapper({ propsData: { isFullScreen: true } });
    });

    it('renders minimize button with the correct props', () => {
      expect(findButton(2).props('icon')).toBe('minimize');
      expect(findButton(2).attributes('title')).toBe('Exit full screen');
      expect(findButton(2).attributes('aria-label')).toBe('Exit full screen');
    });
  });

  describe('when isFollowing prop is provided', () => {
    beforeEach(() => {
      createWrapper({ propsData: { isFollowing: true } });
    });

    it('renders scroll_down button as selected', () => {
      expect(findButton(0).props('selected')).toBe(true);
    });
  });

  describe('when slot is provided', () => {
    const customSlot = '<span>custom value</span>';

    beforeEach(() => {
      createWrapper({ slots: { default: customSlot } });
    });

    it('renders label slot content', () => {
      expect(wrapper.html()).toContain(customSlot);
    });
  });
});
