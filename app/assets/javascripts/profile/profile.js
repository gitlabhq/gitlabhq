import $ from 'jquery';
import Vue from 'vue';
import { VARIANT_DANGER, VARIANT_INFO, createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { parseBoolean } from '~/lib/utils/common_utils';
import { parseRailsFormFields } from '~/lib/utils/forms';
import { Rails } from '~/lib/utils/rails_ujs';
import UserProfileSetStatusWrapper from '~/set_status_modal/user_profile_set_status_wrapper.vue';

export default class Profile {
  constructor({ form } = {}) {
    this.onSubmitForm = this.onSubmitForm.bind(this);
    this.form = form || $('.js-edit-user');
    this.setRepoRadio();
    this.bindEvents();
    this.initAvatarGlCrop();
    this.form.attr('data-testid', 'form-ready');
  }

  initAvatarGlCrop() {
    const cropOpts = {
      filename: '.js-avatar-filename',
      previewImage: '.avatar-image .gl-avatar',
      modalCrop: '.modal-profile-crop',
      pickImageEl: '.js-choose-user-avatar-button',
      uploadImageBtn: '.js-upload-user-avatar',
      modalCropImg: document.querySelector('.modal-profile-crop-image'),
    };
    this.avatarGlCrop = $('.js-user-avatar-input').glCrop(cropOpts).data('glcrop');
  }

  bindEvents() {
    $('.js-preferences-form').on('change.preference', 'input[type=radio]', this.submitForm);
    $('#user_notified_of_own_activity').on('change', this.submitForm);
    this.form.on('submit', this.onSubmitForm);
  }

  submitForm() {
    const $form = $(this).parents('form');

    if ($form.data('remote')) {
      Rails.fire($form[0], 'submit');
    } else {
      $form.submit();
    }
  }

  onSubmitForm(e) {
    e.preventDefault();
    return this.saveForm();
  }

  saveForm() {
    const self = this;
    const formData = new FormData(this.form.get(0));
    const avatarBlob = this.avatarGlCrop.getBlob();

    if (avatarBlob != null) {
      formData.append('user[avatar]', avatarBlob, 'avatar.png');
    }

    formData.delete('user[avatar]-trigger');

    axios({
      method: this.form.attr('method'),
      url: this.form.attr('action'),
      data: formData,
    })
      .then(({ data }) => {
        if (avatarBlob != null) {
          this.updateHeaderAvatar();
        }

        createAlert({
          message: data.message,
          variant: data.status === 'error' ? VARIANT_DANGER : VARIANT_INFO,
        });
      })
      .then(() => {
        window.scrollTo(0, 0);
        // Enable submit button after requests ends
        self.form.find(':input[disabled]').enable();
      })
      .catch((error) =>
        createAlert({
          message: error.message,
          variant: VARIANT_DANGER,
        }),
      );
  }

  updateHeaderAvatar() {
    const url = URL.createObjectURL(this.avatarGlCrop.getBlob());

    document.dispatchEvent(new CustomEvent('userAvatar:update', { detail: { url } }));
  }

  setRepoRadio() {
    const multiEditRadios = $('input[name="user[multi_file]"]');
    if (parseBoolean(this.newRepoActivated)) {
      multiEditRadios.filter('[value=on]').prop('checked', true);
    } else {
      multiEditRadios.filter('[value=off]').prop('checked', true);
    }
  }
}

export const initSetStatusForm = () => {
  const el = document.getElementById('js-user-profile-set-status-form');

  if (!el) {
    return null;
  }

  const fields = parseRailsFormFields(el);

  return new Vue({
    el,
    name: 'UserProfileStatusForm',
    provide: {
      fields,
    },
    render(h) {
      return h(UserProfileSetStatusWrapper);
    },
  });
};
