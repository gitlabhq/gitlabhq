import { nextTick } from 'vue';
import jQuery from 'jquery';
import { GlAvatar, GlAvatarLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { avatarI18n } from '~/profile/edit/constants';
import { loadCSSFile } from '~/lib/utils/css_utils';

import UserAvatar from '~/profile/edit/components/user_avatar.vue';

const glCropDataMock = jest.fn().mockImplementation(() => ({
  getBlob: jest.fn(),
}));

const jQueryMock = {
  glCrop: jest.fn().mockReturnValue({
    data: glCropDataMock,
  }),
};

jest.mock(`~/lib/utils/css_utils`);
jest.mock('jquery');

describe('Edit User Avatar', () => {
  let wrapper;

  beforeEach(() => {
    jQuery.mockImplementation(() => jQueryMock);
  });

  const defaultProvides = {
    avatarUrl: '/-/profile/avatarUrl',
    brandProfileImageGuidelines: '',
    cropperCssPath: '',
    hasAvatar: true,
    gravatarEnabled: true,
    gravatarLink: {
      hostname: 'gravatar.com',
      url: 'gravatar.com',
    },
    profileAvatarPath: '/profile/avatar',
  };

  const createComponent = (provides = {}) => {
    wrapper = shallowMountExtended(UserAvatar, {
      provide: {
        ...defaultProvides,
        ...provides,
      },
      attachTo: document.body,
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findHelpText = () => wrapper.findComponent(GlSprintf).attributes('message');
  const findRemoveAvatarButton = () => wrapper.findByTestId('remove-avatar-button');

  describe('renders correctly', () => {
    it('under default condition', async () => {
      createComponent();
      await nextTick();

      expect(jQueryMock.glCrop).toHaveBeenCalledWith({
        filename: '.js-avatar-filename',
        previewImage: '.avatar-image .gl-avatar',
        modalCrop: '.modal-profile-crop',
        pickImageEl: '.js-choose-user-avatar-button',
        uploadImageBtn: '.js-upload-user-avatar',
        modalCropImg: expect.any(HTMLImageElement),
        onBlobChange: expect.any(Function),
      });
      expect(glCropDataMock).toHaveBeenCalledWith('glcrop');
      expect(loadCSSFile).toHaveBeenCalledWith(defaultProvides.cropperCssPath);
      const avatar = findAvatar();

      expect(avatar.exists()).toBe(true);
      expect(avatar.attributes('src')).toBe(defaultProvides.avatarUrl);
      expect(findAvatarLink().attributes('href')).toBe(defaultProvides.avatarUrl);

      const removeAvatarButton = findRemoveAvatarButton();
      expect(removeAvatarButton.exists()).toBe(true);
      expect(removeAvatarButton.attributes('href')).toBe(defaultProvides.profileAvatarPath);
    });

    describe('when user has avatar', () => {
      describe('while gravatar is enabled', () => {
        it('shows help text for change or remove avatar', () => {
          createComponent({
            gravatarEnabled: true,
          });

          expect(findHelpText()).toBe(avatarI18n.changeOrRemoveAvatar);
        });
      });
      describe('while gravatar is disabled', () => {
        it('shows help text for change avatar', () => {
          createComponent({
            gravatarEnabled: false,
          });

          expect(findHelpText()).toBe(avatarI18n.changeAvatar);
        });
      });
    });

    describe('when user does not have an avatar', () => {
      describe('while gravatar is enabled', () => {
        it('shows help text for upload or change avatar', () => {
          createComponent({
            gravatarEnabled: true,
            hasAvatar: false,
          });
          expect(findHelpText()).toBe(avatarI18n.uploadOrChangeAvatar);
        });
      });

      describe('while gravatar is disabled', () => {
        it('shows help text for upload avatar', () => {
          createComponent({
            gravatarEnabled: false,
            hasAvatar: false,
          });
          expect(findHelpText()).toBe(avatarI18n.uploadAvatar);
          expect(findRemoveAvatarButton().exists()).toBe(false);
        });
      });
    });
  });

  it('can render profile image guidelines', () => {
    const brandProfileImageGuidelines = 'brandProfileImageGuidelines';
    createComponent({
      brandProfileImageGuidelines,
    });

    expect(wrapper.findByTestId('brand-profile-image-guidelines').text()).toBe(
      brandProfileImageGuidelines,
    );
  });
});
