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
    this.$loadingIcon = this.$wrapper.find('.fa-chevron-down');
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

  getToggleText() {
    return this.$dropdownToggleText.text();
  }

  setToggleText(text) {
    this.$dropdownToggleText.text(text);
  }

  renderLoading() {
    this.$loadingIcon
      .addClass('fa-spinner fa-spin')
      .removeClass('fa-chevron-down');
  }

  renderLoaded() {
    this.$loadingIcon
      .addClass('fa-chevron-down')
      .removeClass('fa-spinner fa-spin');
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
