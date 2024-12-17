<script>
import $ from 'jquery';
import { GlAvatar, GlAvatarLink, GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { loadCSSFile } from '~/lib/utils/css_utils';
import SafeHtmlDirective from '~/vue_shared/directives/safe_html';

import { avatarI18n } from '../constants';

export default {
  name: 'EditProfileUserAvatar',
  components: {
    GlAvatar,
    GlAvatarLink,
    GlButton,
    GlLink,
    GlSprintf,
  },
  directives: {
    SafeHtml: SafeHtmlDirective,
  },
  inject: [
    'avatarUrl',
    'brandProfileImageGuidelines',
    'cropperCssPath',
    'hasAvatar',
    'gravatarEnabled',
    'gravatarLink',
    'profileAvatarPath',
  ],
  computed: {
    avatarHelpText() {
      const { changeOrRemoveAvatar, changeAvatar, uploadOrChangeAvatar, uploadAvatar } = avatarI18n;
      if (this.hasAvatar) {
        return this.gravatarEnabled ? changeOrRemoveAvatar : changeAvatar;
      }
      return this.gravatarEnabled ? uploadOrChangeAvatar : uploadAvatar;
    },
  },

  mounted() {
    this.initializeCropper();
    loadCSSFile(this.cropperCssPath);
  },

  methods: {
    initializeCropper() {
      const cropOpts = {
        filename: '.js-avatar-filename',
        previewImage: '.avatar-image .gl-avatar',
        modalCrop: '.modal-profile-crop',
        pickImageEl: '.js-choose-user-avatar-button',
        uploadImageBtn: '.js-upload-user-avatar',
        modalCropImg: document.querySelector('.modal-profile-crop-image'),
        onBlobChange: this.onBlobChange,
      };
      // This has to be used with jQuery, considering migrate that from jQuery to Vue in the future.
      $('.js-user-avatar-input').glCrop(cropOpts).data('glcrop');
    },
    onBlobChange(blob) {
      this.$emit('blob-change', blob);
    },
  },
  i18n: avatarI18n,
};
</script>

<template>
  <div class="js-search-settings-section gl-pb-6">
    <div class="profile-settings-sidebar">
      <h4 class="gl-my-0">
        {{ $options.i18n.publicAvatar }}
      </h4>
      <p class="gl-text-subtle">
        <gl-sprintf :message="avatarHelpText">
          <template #gravatar_link>
            <gl-link :href="gravatarLink.url" target="__blank">
              {{ gravatarLink.hostname }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
      <div
        v-if="brandProfileImageGuidelines"
        v-safe-html="brandProfileImageGuidelines"
        class="md gl-mb-5"
        data-testid="brand-profile-image-guidelines"
      ></div>
    </div>
    <div class="gl-flex">
      <div class="avatar-image">
        <gl-avatar-link :href="avatarUrl" target="blank">
          <gl-avatar class="gl-mr-5" :src="avatarUrl" :size="96" shape="circle" />
        </gl-avatar-link>
      </div>
      <div class="gl-grow">
        <h5 class="gl-mt-0">
          {{ $options.i18n.uploadNewAvatar }}
        </h5>
        <div class="gl-my-3 gl-flex gl-items-center">
          <gl-button class="js-choose-user-avatar-button">
            {{ $options.i18n.chooseFile }}
          </gl-button>
          <span class="js-avatar-filename gl-ml-3">{{ $options.i18n.noFileChosen }}</span>
          <input
            id="user_avatar"
            class="js-user-avatar-input hidden"
            accept="image/*"
            type="file"
            name="user[avatar]"
          />
        </div>
        <p class="gl-mb-0 gl-text-subtle">
          {{ $options.i18n.imageDimensions }}
          {{ $options.i18n.maximumFileSize }}
        </p>
        <gl-button
          v-if="hasAvatar"
          class="gl-mt-3"
          category="secondary"
          variant="danger"
          data-method="delete"
          rel="nofollow"
          data-testid="remove-avatar-button"
          :data-confirm="$options.i18n.removeAvatarConfirmation"
          :href="profileAvatarPath"
        >
          {{ $options.i18n.removeAvatar }}
        </gl-button>
      </div>
    </div>
    <!-- For bs.modal to take over -->
    <div class="modal modal-profile-crop" :data-cropper-css-path="cropperCssPath">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h4 class="modal-title">
              {{ $options.i18n.cropAvatarTitle }}
            </h4>
            <gl-button
              category="tertiary"
              icon="close"
              class="close"
              data-dismiss="modal"
              :aria-label="__('Close')"
            />
          </div>
          <div class="modal-body">
            <div class="profile-crop-image-container">
              <img :alt="$options.i18n.cropAvatarImageAltText" class="modal-profile-crop-image" />
            </div>
            <div class="gl-mt-4 gl-text-center">
              <div class="btn-group">
                <gl-button
                  :aria-label="__('Zoom out')"
                  icon="search-minus"
                  data-method="zoom"
                  data-option="-0.1"
                />
                <gl-button
                  :aria-label="__('Zoom in')"
                  icon="search-plus"
                  data-method="zoom"
                  data-option="0.1"
                />
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <gl-button class="js-upload-user-avatar" variant="confirm">{{
              $options.i18n.cropAvatarSetAsNewAvatar
            }}</gl-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
