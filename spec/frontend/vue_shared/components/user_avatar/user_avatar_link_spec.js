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

  const createWrapper = (props = {}, { glAvatarForAllUserAvatars } = {}) => {
    wrapper = shallowMount(UserAvatarLink, {
      propsData: {
        ...PROVIDED_PROPS,
        ...props,
      },
      provide: {
        glFeatures: {
          glAvatarForAllUserAvatars,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each([
    [false, true, true],
    [true, false, true],
    [true, true, true],
    [false, false, false],
  ])(
    'when glAvatarForAllUserAvatars=%s and enforceGlAvatar=%s',
    (glAvatarForAllUserAvatars, enforceGlAvatar, isUsingNewVersion) => {
      it(`will render ${isUsingNewVersion ? 'new' : 'old'} version`, () => {
        createWrapper({ enforceGlAvatar }, { glAvatarForAllUserAvatars });
        expect(wrapper.findComponent(UserAvatarLinkNew).exists()).toBe(isUsingNewVersion);
        expect(wrapper.findComponent(UserAvatarLinkOld).exists()).toBe(!isUsingNewVersion);
      });
    },
  );
});
