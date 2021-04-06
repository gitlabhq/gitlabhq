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
    this.selectInitialTemplate();
  }

  selectInitialTemplate() {
    const template = this.$dropdown.data('selected');

    if (!template) {
      return;
    }

    this.mediator.selectTemplateFile(this, template);
  }

  show() {
    if (this.$dropdown === null) {
      this.init();
    }

    this.$wrapper.removeClass('hidden');

    /**
     * We set the focus on the dropdown that was just shown. This is done so that, after selecting
     * a template type, the template selector immediately receives the focus.
     * This improves the UX of the tour as the suggest_gitlab_ci_yml popover requires its target to
     * be have the focus to appear. This way, users don't have to interact with the template
     * selector to actually see the first hint: it is shown as soon as the selector becomes visible.
     * We also need a timeout here, otherwise the template type selector gets stuck and can not be
     * closed anymore.
     */
    setTimeout(() => {
      this.$dropdown.focus();
    }, 0);
  }

  hide() {
    if (this.$dropdown !== null) {
      this.$wrapper.addClass('hidden');
    }
  }

  isHidden() {
    return !this.$wrapper || this.$wrapper.hasClass('hidden');
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
    opts.data = options.selectedObj;
    opts.data.source_template_project_id = options.selectedObj.project_id;

    this.reportSelection(opts);
  }
}
