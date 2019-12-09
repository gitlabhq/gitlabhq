import { shallowMount } from '@vue/test-utils';
import defaultAvatarUrl from 'images/no_avatar.png';
import { placeholderImage } from '~/lazy_loader';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

jest.mock('images/no_avatar.png', () => 'default-avatar-url');

const DEFAULT_PROPS = {
  size: 99,
  imgSrc: 'myavatarurl.com',
  imgAlt: 'mydisplayname',
  cssClasses: 'myextraavatarclass',
  tooltipText: 'tooltip text',
  tooltipPlacement: 'bottom',
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
          ...DEFAULT_PROPS,
        },
        sync: false,
      });
    });

    it('should have <img> as a child element', () => {
      const imageElement = wrapper.find('img');

      expect(imageElement.exists()).toBe(true);
      expect(imageElement.attributes('src')).toBe(`${DEFAULT_PROPS.imgSrc}?width=99`);
      expect(imageElement.attributes('data-src')).toBe(`${DEFAULT_PROPS.imgSrc}?width=99`);
      expect(imageElement.attributes('alt')).toBe(DEFAULT_PROPS.imgAlt);
    });

    it('should properly render img css', () => {
      const classes = wrapper.find('img').classes();
      expect(classes).toEqual(expect.arrayContaining(['avatar', 's99', DEFAULT_PROPS.cssClasses]));
      expect(classes).not.toContain('lazy');
    });
  });

  describe('Initialization when lazy', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, {
        propsData: {
          ...DEFAULT_PROPS,
          lazy: true,
        },
        sync: false,
      });
    });

    it('should add lazy attributes', () => {
      const imageElement = wrapper.find('img');

      expect(imageElement.classes()).toContain('lazy');
      expect(imageElement.attributes('src')).toBe(placeholderImage);
      expect(imageElement.attributes('data-src')).toBe(`${DEFAULT_PROPS.imgSrc}?width=99`);
    });
  });

  describe('Initialization without src', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, { sync: false });
    });

    it('should have default avatar image', () => {
      const imageElement = wrapper.find('img');

      expect(imageElement.attributes('src')).toBe(`${defaultAvatarUrl}?width=20`);
    });
  });

  describe('dynamic tooltip content', () => {
    const props = DEFAULT_PROPS;
    const slots = {
      default: ['Action!'],
    };

    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, { propsData: { props }, slots, sync: false });
    });

    it('renders the tooltip slot', () => {
      expect(wrapper.find('.js-user-avatar-image-toolip').exists()).toBe(true);
    });

    it('renders the tooltip content', () => {
      expect(wrapper.find('.js-user-avatar-image-toolip').text()).toContain(slots.default[0]);
    });

    it('does not render tooltip data attributes for on avatar image', () => {
      const avatarImg = wrapper.find('img');

      expect(avatarImg.attributes('data-original-title')).toBeFalsy();
      expect(avatarImg.attributes('data-placement')).not.toBeDefined();
      expect(avatarImg.attributes('data-container')).not.toBeDefined();
    });
  });
});
