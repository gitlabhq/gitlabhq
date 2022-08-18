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

  const createWrapper = (props = {}, { glAvatarForAllUserAvatars } = {}) => {
    wrapper = shallowMount(UserAvatarImage, {
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
        expect(wrapper.findComponent(UserAvatarImageNew).exists()).toBe(isUsingNewVersion);
        expect(wrapper.findComponent(UserAvatarImageOld).exists()).toBe(!isUsingNewVersion);
      });
    },
  );
});
