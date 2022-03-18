import { shallowMount } from '@vue/test-utils';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import UserAvatarImageNew from '~/vue_shared/components/user_avatar/user_avatar_image_new.vue';
import UserAvatarImageOld from '~/vue_shared/components/user_avatar/user_avatar_image_old.vue';

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

  describe('when `glAvatarForAllUserAvatars` feature flag enabled', () => {
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

    it('should render `UserAvatarImageNew` component', () => {
      expect(wrapper.findComponent(UserAvatarImageNew).exists()).toBe(true);
      expect(wrapper.findComponent(UserAvatarImageOld).exists()).toBe(false);
    });
  });

  describe('when `glAvatarForAllUserAvatars` feature flag disabled', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarImage, {
        propsData: {
          ...PROVIDED_PROPS,
        },
        provide: {
          glFeatures: {
            glAvatarForAllUserAvatars: false,
          },
        },
      });
    });

    it('should render `UserAvatarImageOld` component', () => {
      expect(wrapper.findComponent(UserAvatarImageNew).exists()).toBe(false);
      expect(wrapper.findComponent(UserAvatarImageOld).exists()).toBe(true);
    });
  });
});
