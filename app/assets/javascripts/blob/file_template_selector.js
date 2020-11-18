import $ from 'jquery';

export default class FileTemplateSelector {
  constructor(mediator) {
    this.mediator = mediator;
    this.$dropdown = null;
    this.$wrapper = null;
  }

  init() {
    const cfg = this.config;

    this.$dropdown = $(cfg.dropdown);
    this.$wrapper = $(cfg.wrapper);
    this.$dropdownIcon = this.$wrapper.find('.dropdown-menu-toggle-icon');
    this.$loadingIcon = $(
      '<div class="gl-spinner gl-spinner-orange gl-spinner-sm gl-absolute gl-top-3 gl-right-3 gl-display-none"></div>',
    ).insertAfter(this.$dropdownIcon);
    this.$dropdownToggleText = this.$wrapper.find('.dropdown-toggle-text');

    this.initDropdown();
  }

  show() {
    if (this.$dropdown === null) {
      this.init();
    }

    this.$wrapper.removeClass('hidden');
  }

  hide() {
    if (this.$dropdown !== null) {
      this.$wrapper.addClass('hidden');
    }
  }

  isHidden() {
    return this.$wrapper.hasClass('hidden');
  }

  getToggleText() {
    return this.$dropdownToggleText.text();
  }

  setToggleText(text) {
    this.$dropdownToggleText.text(text);
  }

  renderLoading() {
    this.$loadingIcon.removeClass('gl-display-none');
    this.$dropdownIcon.addClass('gl-display-none');
  }

  renderLoaded() {
    this.$loadingIcon.addClass('gl-display-none');
    this.$dropdownIcon.removeClass('gl-display-none');
  }

  reportSelection(options) {
    const { query, e, data } = options;
    e.preventDefault();
    return this.mediator.selectTemplateFile(this, query, data);
  }

  reportSelectionName(options) {
    const opts = options;
    opts.query = options.selectedObj.name;

    this.reportSelection(opts);
  }
}
