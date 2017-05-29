/* global Flash */

export default class IntegrationSettingsForm {
  constructor(formSelector) {
    this.$form = $(formSelector);

    // Form Metadata
    this.endPoint = this.$form.attr('action');
    this.canTestService = this.$form.data('can-test');

    // Form Child Elements
    this.$serviceToggle = this.$form.find('#service_active');
    this.$submitBtn = this.$form.find('button[type="submit"]');
    this.$submitBtnLoader = this.$submitBtn.find('.js-btn-spinner');
    this.$submitBtnLabel = this.$submitBtn.find('.js-btn-label');

    // Class Member methods
    this.handleServiceToggle = this.handleServiceToggle.bind(this);
    this.handleSettingsSave = this.handleSettingsSave.bind(this);

    this.init();
  }

  init() {
    // Initialize View
    this.toggleServiceState(this.$serviceToggle.is(':checked'));

    // Bind Event Listeners
    this.$serviceToggle.on('change', this.handleServiceToggle);
    this.$submitBtn.on('click', this.handleSettingsSave);
  }

  handleSettingsSave(e) {
    if (this.$serviceToggle.is(':checked')) {
      if (this.$form.get(0).checkValidity() &&
          this.canTestService) {
        e.preventDefault();
        this.testSettings(this.$form.serialize());
      }
    }
  }

  handleServiceToggle(e) {
    this.toggleServiceState($(e.currentTarget).is(':checked'));
  }

  toggleServiceState(serviceActive) {
    this.toggleSubmitBtnLabel(serviceActive, this.canTestService);
    if (serviceActive) {
      this.$form.removeAttr('novalidate');
    } else if (!this.$form.attr('novalidate')) {
      this.$form.attr('novalidate', 'novalidate');
    }
  }

  /**
   * Toggle Submit button label based on Integration status
   */
  toggleSubmitBtnLabel(serviceActive, canTestService) {
    this.$submitBtnLabel.text(
      serviceActive && canTestService ?
        'Test settings and save changes' :
        'Save changes');
  }

  /**
   * Toggle Submit button state based on provided boolean value of `saveTestActive`
   * When enabled, it does two things, and reverts back when disabled
   *
   * 1. It shows load spinner on submit button
   * 2. Makes submit button disabled
   */
  toggleSubmitBtnState(saveTestActive) {
    if (saveTestActive) {
      this.$submitBtn.disable();
      this.$submitBtnLoader.removeClass('hidden');
    } else {
      this.$submitBtn.enable();
      this.$submitBtnLoader.addClass('hidden');
    }
  }

  /* eslint-disable promise/catch-or-return, no-new */
  /**
   * Test Integration config
   */
  testSettings(formData) {
    this.toggleSubmitBtnState(true);
    $.ajax({
      type: 'PUT',
      url: `${this.endPoint}/test`,
      data: formData,
    })
    .done((res) => {
      if (res.error) {
        new Flash(`${res.message}.`, null, null, {
          title: 'Save anyway',
          clickHandler: (e) => {
            e.preventDefault();
            this.$form.submit();
          },
        });
      } else {
        this.$form.submit();
      }
    })
    .fail(() => {
      new Flash('Something went wrong on our end.');
    })
    .always(() => {
      this.toggleSubmitBtnState(false);
    });
  }
}
