import { shallowMount } from '@vue/test-utils';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarLinkNew from '~/vue_shared/components/user_avatar/user_avatar_link_new.vue';
import UserAvatarLinkOld from '~/vue_shared/components/user_avatar/user_avatar_link_old.vue';

const PROVIDED_PROPS = {
  size: 32,
  imgSrc: 'myavatarurl.com',
  imgAlt: 'mydisplayname',
  cssClasses: 'myextraavatarclass',
  tooltipText: 'tooltip text',
  tooltipPlacement: 'bottom',
};

describe('User Avatar Link Component', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when `glAvatarForAllUserAvatars` feature flag enabled', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarLink, {
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

    it('should render `UserAvatarLinkNew` component', () => {
      expect(wrapper.findComponent(UserAvatarLinkNew).exists()).toBe(true);
      expect(wrapper.findComponent(UserAvatarLinkOld).exists()).toBe(false);
    });
  });

  describe('when `glAvatarForAllUserAvatars` feature flag disabled', () => {
    beforeEach(() => {
      wrapper = shallowMount(UserAvatarLink, {
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

    it('should render `UserAvatarLinkOld` component', () => {
      expect(wrapper.findComponent(UserAvatarLinkNew).exists()).toBe(false);
      expect(wrapper.findComponent(UserAvatarLinkOld).exists()).toBe(true);
    });
  });
});
