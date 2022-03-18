import { shallowMount } from '@vue/test-utils';
import { GlTooltip } from '@gitlab/ui';
import defaultAvatarUrl from 'images/no_avatar.png';
import { placeholderImage } from '~/lazy_loader';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image_old.vue';

jest.mock('images/no_avatar.png', () => 'default-avatar-url');

const PROVIDED_PROPS = {
  size: 32,
  imgSrc: 'myavatarurl.com',
  imgAlt: 'mydisplayname',
  cssClasses: 'myextraavatarclass',
  tooltipText: 'tooltip text',
  tooltipPlacement: 'bottom',
};

const DEFAULT_PROPS = {
  size: 20,
};

describe('User Avatar Image Component', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Initialization', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, {
        propsData: {
          ...PROVIDED_PROPS,
        },
      });
    });

    it('should have <img> as a child element', () => {
      const imageElement = wrapper.find('img');

      expect(imageElement.exists()).toBe(true);
      expect(imageElement.attributes('src')).toBe(
        `${PROVIDED_PROPS.imgSrc}?width=${PROVIDED_PROPS.size}`,
      );
      expect(imageElement.attributes('data-src')).toBe(
        `${PROVIDED_PROPS.imgSrc}?width=${PROVIDED_PROPS.size}`,
      );
      expect(imageElement.attributes('alt')).toBe(PROVIDED_PROPS.imgAlt);
    });

    it('should properly render img css', () => {
      const classes = wrapper.find('img').classes();
      expect(classes).toEqual(['avatar', 's32', PROVIDED_PROPS.cssClasses]);
      expect(classes).not.toContain('lazy');
    });
  });

  describe('Initialization when lazy', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, {
        propsData: {
          ...PROVIDED_PROPS,
          lazy: true,
        },
      });
    });

    it('should add lazy attributes', () => {
      const imageElement = wrapper.find('img');

      expect(imageElement.classes()).toContain('lazy');
      expect(imageElement.attributes('src')).toBe(placeholderImage);
      expect(imageElement.attributes('data-src')).toBe(
        `${PROVIDED_PROPS.imgSrc}?width=${PROVIDED_PROPS.size}`,
      );
    });
  });

  describe('Initialization without src', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage);
    });

    it('should have default avatar image', () => {
      const imageElement = wrapper.find('img');

      expect(imageElement.attributes('src')).toBe(
        `${defaultAvatarUrl}?width=${DEFAULT_PROPS.size}`,
      );
    });
  });

  describe('dynamic tooltip content', () => {
    const props = PROVIDED_PROPS;
    const slots = {
      default: ['Action!'],
    };

    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, {
        propsData: { props },
        slots,
      });
    });

    it('renders the tooltip slot', () => {
      expect(wrapper.findComponent(GlTooltip).exists()).toBe(true);
    });

    it('renders the tooltip content', () => {
      expect(wrapper.findComponent(GlTooltip).text()).toContain(slots.default[0]);
    });

    it('does not render tooltip data attributes on avatar image', () => {
      const avatarImg = wrapper.find('img');

      expect(avatarImg.attributes('title')).toBeFalsy();
      expect(avatarImg.attributes('data-placement')).not.toBeDefined();
      expect(avatarImg.attributes('data-container')).not.toBeDefined();
    });
  });
});
