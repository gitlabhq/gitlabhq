import $ from 'jquery';

export default class UserInternalRegexHandler {
  constructor() {
    this.regexPattern = $('[data-user-internal-regex-pattern]').data('user-internal-regex-pattern');
    if (this.regexPattern && this.regexPattern !== '') {
      this.regexOptions = $('[data-user-internal-regex-options]').data('user-internal-regex-options');
      this.external = $('#user_external');
      this.warningMessage = $('#warning_external_automatically_set');
      this.addListenerToEmailField();
      this.addListenerToUserExternalCheckbox();
    }
  }

  addListenerToEmailField() {
    $('#user_email').on('input', (event) => {
      this.setExternalCheckbox(event.currentTarget.value);
    });
  }

  addListenerToUserExternalCheckbox() {
    this.external.on('click', () => {
      this.warningMessage.addClass('hidden');
    });
  }

  isEmailInternal(email) {
    const regex = new RegExp(this.regexPattern, this.regexOptions);
    return regex.test(email);
  }

  setExternalCheckbox(email) {
    const isChecked = this.external.prop('checked');
    if (this.isEmailInternal(email)) {
      if (isChecked) {
        this.external.prop('checked', false);
        this.warningMessage.removeClass('hidden');
      }
    } else if (!isChecked) {
      this.external.prop('checked', true);
      this.warningMessage.addClass('hidden');
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  // eslint-disable-next-line
  new UserInternalRegexHandler();
});
