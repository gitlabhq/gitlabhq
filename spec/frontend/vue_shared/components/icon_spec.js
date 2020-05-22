import Vue from 'vue';
import { mount } from '@vue/test-utils';
import mountComponent from 'helpers/vue_mount_component_helper';
import Icon from '~/vue_shared/components/icon.vue';
import iconsPath from '@gitlab/svgs/dist/icons.svg';

jest.mock('@gitlab/svgs/dist/icons.svg', () => 'testing');

describe('Sprite Icon Component', () => {
  describe('Initialization', () => {
    let icon;

    beforeEach(() => {
      const IconComponent = Vue.extend(Icon);

      icon = mountComponent(IconComponent, {
        name: 'commit',
        size: 32,
      });
    });

    afterEach(() => {
      icon.$destroy();
    });

    it('should return a defined Vue component', () => {
      expect(icon).toBeDefined();
    });

    it('should have <svg> as a child element', () => {
      expect(icon.$el.tagName).toBe('svg');
    });

    it('should have <use> as a child element with the correct href', () => {
      expect(icon.$el.firstChild.tagName).toBe('use');
      expect(icon.$el.firstChild.getAttribute('xlink:href')).toBe(`${iconsPath}#commit`);
    });

    it('should properly compute iconSizeClass', () => {
      expect(icon.iconSizeClass).toBe('s32');
    });

    it('forbids invalid size prop', () => {
      expect(icon.$options.props.size.validator(NaN)).toBeFalsy();
      expect(icon.$options.props.size.validator(0)).toBeFalsy();
      expect(icon.$options.props.size.validator(9001)).toBeFalsy();
    });

    it('should properly render img css', () => {
      const { classList } = icon.$el;
      const containsSizeClass = classList.contains('s32');

      expect(containsSizeClass).toBe(true);
    });

    it('`name` validator should return false for non existing icons', () => {
      jest.spyOn(console, 'warn').mockImplementation();

      expect(Icon.props.name.validator('non_existing_icon_sprite')).toBe(false);
    });

    it('`name` validator should return true for existing icons', () => {
      expect(Icon.props.name.validator('commit')).toBe(true);
    });
  });

  it('should call registered listeners when they are triggered', () => {
    const clickHandler = jest.fn();
    const wrapper = mount(Icon, {
      propsData: { name: 'commit' },
      listeners: { click: clickHandler },
    });

    wrapper.find('svg').trigger('click');

    expect(clickHandler).toHaveBeenCalled();
  });
});
