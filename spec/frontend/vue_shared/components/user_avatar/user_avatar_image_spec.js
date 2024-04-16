import { shallowMount } from '@vue/test-utils';
import { GlAvatar, GlTooltip } from '@gitlab/ui';
import defaultAvatarUrl from 'images/no_avatar.png';
import { placeholderImage } from '~/lazy_loader';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

jest.mock('images/no_avatar.png', () => 'default-avatar-url');

const PROVIDED_PROPS = {
  size: 24,
  imgSrc: 'myavatarurl.com',
  imgAlt: 'mydisplayname',
  cssClasses: 'myextraavatarclass',
  tooltipText: 'tooltip text',
  tooltipPlacement: 'bottom',
};

describe('User Avatar Image Component', () => {
  let wrapper;

  const findAvatar = () => wrapper.findComponent(GlAvatar);

  describe('Initialization', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, {
        propsData: {
          ...PROVIDED_PROPS,
        },
      });
    });

    it('should render `GlAvatar` and provide correct properties to it', () => {
      expect(findAvatar().attributes('data-src')).toBe(
        `${PROVIDED_PROPS.imgSrc}?width=${PROVIDED_PROPS.size * 2}`,
      );
      expect(findAvatar().props()).toMatchObject({
        src: `${PROVIDED_PROPS.imgSrc}?width=${PROVIDED_PROPS.size * 2}`,
        alt: PROVIDED_PROPS.imgAlt,
        size: PROVIDED_PROPS.size,
      });
    });

    it('should add correct CSS classes', () => {
      const classes = wrapper.findComponent(GlAvatar).classes();
      expect(classes).toContain(PROVIDED_PROPS.cssClasses);
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
      expect(findAvatar().classes()).toContain('lazy');
      expect(findAvatar().attributes()).toMatchObject({
        src: placeholderImage,
        'data-src': `${PROVIDED_PROPS.imgSrc}?width=${PROVIDED_PROPS.size * 2}`,
      });
    });

    it('should use maximum number when size is provided as an object', () => {
      wrapper = shallowMount(UserAvatarImage, {
        propsData: {
          ...PROVIDED_PROPS,
          size: { default: 16, md: 64, lg: 24 },
          lazy: true,
        },
      });

      expect(findAvatar().attributes('data-src')).toBe(`${PROVIDED_PROPS.imgSrc}?width=${128}`);
    });
  });

  describe('Initialization without src', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, {
        propsData: {
          ...PROVIDED_PROPS,
          imgSrc: null,
        },
      });
    });

    it('should have default avatar image', () => {
      expect(findAvatar().props('src')).toBe(
        `${defaultAvatarUrl}?width=${PROVIDED_PROPS.size * 2}`,
      );
    });

    it.each`
      size                               | expected
      ${96}                              | ${192}
      ${64}                              | ${128}
      ${48}                              | ${96}
      ${32}                              | ${64}
      ${24}                              | ${48}
      ${16}                              | ${32}
      ${{ default: 16, md: 32, lg: 24 }} | ${64}
      ${{ default: 16, md: 32, lg: 96 }} | ${192}
    `(
      'should use the $expected x $expected source image if the size provided is $size',
      ({ size, expected }) => {
        wrapper = shallowMount(UserAvatarImage, {
          propsData: {
            ...PROVIDED_PROPS,
            size,
          },
        });
        expect(findAvatar().props('src')).toBe(`${PROVIDED_PROPS.imgSrc}?width=${expected}`);
      },
    );
  });

  describe('Dynamic tooltip content', () => {
    const slots = {
      default: ['Action!'],
    };

    describe('when `tooltipText` is provided and no default slot', () => {
      beforeEach(() => {
        wrapper = shallowMount(UserAvatarImage, {
          propsData: { ...PROVIDED_PROPS },
        });
      });

      it('renders the tooltip with `tooltipText` as content', () => {
        expect(wrapper.findComponent(GlTooltip).text()).toBe(PROVIDED_PROPS.tooltipText);
      });
    });

    describe('when `tooltipText` and default slot is provided', () => {
      beforeEach(() => {
        wrapper = shallowMount(UserAvatarImage, {
          propsData: { ...PROVIDED_PROPS },
          slots,
        });
      });

      it('does not render `tooltipText` inside the tooltip', () => {
        expect(wrapper.findComponent(GlTooltip).text()).not.toBe(PROVIDED_PROPS.tooltipText);
      });

      it('renders the content provided via default slot', () => {
        expect(wrapper.findComponent(GlTooltip).text()).toContain(slots.default[0]);
      });
    });
  });

  describe('when pseudo prop is true', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, {
        propsData: { ...PROVIDED_PROPS, pseudo: true },
      });
    });

    it('passes image to GlAvatar through style attribute', () => {
      // using falsy here to avoid issues with Vue 3
      // eslint-disable-next-line jest/no-restricted-matchers
      expect(wrapper.findComponent(GlAvatar).props('src')).toBeFalsy();
      expect(wrapper.findComponent(GlAvatar).attributes('style')).toBe(
        `background-image: url(${PROVIDED_PROPS.imgSrc}?width=${PROVIDED_PROPS.size * 2});`,
      );
    });
  });
});
