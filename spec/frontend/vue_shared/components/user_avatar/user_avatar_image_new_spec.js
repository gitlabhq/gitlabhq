import { shallowMount } from '@vue/test-utils';
import { GlAvatar, GlTooltip } from '@gitlab/ui';
import defaultAvatarUrl from 'images/no_avatar.png';
import { placeholderImage } from '~/lazy_loader';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image_new.vue';

jest.mock('images/no_avatar.png', () => 'default-avatar-url');

const PROVIDED_PROPS = {
  size: 32,
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
          ...PROVIDED_PROPS,
        },
        provide: {
          glFeatures: {
            glAvatarForAllUserAvatars: true,
          },
        },
      });
    });

    it('should render `GlAvatar` and provide correct properties to it', () => {
      const avatar = wrapper.findComponent(GlAvatar);

      expect(avatar.attributes('data-src')).toBe(
        `${PROVIDED_PROPS.imgSrc}?width=${PROVIDED_PROPS.size}`,
      );
      expect(avatar.props()).toMatchObject({
        src: `${PROVIDED_PROPS.imgSrc}?width=${PROVIDED_PROPS.size}`,
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
        provide: {
          glFeatures: {
            glAvatarForAllUserAvatars: true,
          },
        },
      });
    });

    it('should add lazy attributes', () => {
      const avatar = wrapper.findComponent(GlAvatar);

      expect(avatar.classes()).toContain('lazy');
      expect(avatar.attributes()).toMatchObject({
        src: placeholderImage,
        'data-src': `${PROVIDED_PROPS.imgSrc}?width=${PROVIDED_PROPS.size}`,
      });
    });
  });

  describe('Initialization without src', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, {
        propsData: {
          ...PROVIDED_PROPS,
          imgSrc: null,
        },
        provide: {
          glFeatures: {
            glAvatarForAllUserAvatars: true,
          },
        },
      });
    });

    it('should have default avatar image', () => {
      const avatar = wrapper.findComponent(GlAvatar);

      expect(avatar.props('src')).toBe(`${defaultAvatarUrl}?width=${PROVIDED_PROPS.size}`);
    });
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
});
