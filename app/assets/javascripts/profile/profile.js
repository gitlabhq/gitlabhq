import $ from 'jquery';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { parseBoolean } from '~/lib/utils/common_utils';
import { Rails } from '~/lib/utils/rails_ujs';
import TimezoneDropdown, {
  formatTimezone,
} from '~/pages/projects/pipeline_schedules/shared/components/timezone_dropdown';

export default class Profile {
  constructor({ form } = {}) {
    this.onSubmitForm = this.onSubmitForm.bind(this);
    this.form = form || $('.edit-user');
    this.setRepoRadio();
    this.bindEvents();
    this.initAvatarGlCrop();

    this.$inputEl = $('#user_timezone');

    this.timezoneDropdown = new TimezoneDropdown({
      $inputEl: this.$inputEl,
      $dropdownEl: $('.js-timezone-dropdown'),
      displayFormat: (selectedItem) => formatTimezone(selectedItem),
    });
  }

  initAvatarGlCrop() {
    const cropOpts = {
      filename: '.js-avatar-filename',
      previewImage: '.avatar-image .avatar',
      modalCrop: '.modal-profile-crop',
      pickImageEl: '.js-choose-user-avatar-button',
      uploadImageBtn: '.js-upload-user-avatar',
      modalCropImg: '.modal-profile-crop-image',
    };
    this.avatarGlCrop = $('.js-user-avatar-input').glCrop(cropOpts).data('glcrop');
  }

  bindEvents() {
    $('.js-preferences-form').on('change.preference', 'input[type=radio]', this.submitForm);
    $('.js-group-notification-email').on('change', this.submitForm);
    $('#user_notification_email').on('select2-selecting', (event) => {
      setTimeout(this.submitForm.bind(event.currentTarget));
    });
    $('#user_email_opted_in').on('change', this.submitForm);
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

        createFlash({
          message: data.message,
          type: 'notice',
        });
      })
      .then(() => {
        window.scrollTo(0, 0);
        // Enable submit button after requests ends
        self.form.find(':input[disabled]').enable();
      })
      .catch((error) =>
        createFlash({
          message: error.message,
        }),
      );
  }

  updateHeaderAvatar() {
    $('.header-user-avatar').attr('src', this.avatarGlCrop.dataURL);
    $('.js-sidebar-user-avatar').attr('src', this.avatarGlCrop.dataURL);
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
