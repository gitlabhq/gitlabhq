import $ from 'jquery';
import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';

export default class FileTemplateSelector {
  constructor(mediator) {
    this.mediator = mediator;
    this.$dropdown = null;
    this.$wrapper = null;

    this.dropdown = null;
    this.wrapper = null;
  }

  init() {
    const cfg = this.config;

    this.$dropdown = $(cfg.dropdown);
    this.$wrapper = $(cfg.wrapper);

    this.dropdown = document.querySelector(cfg.dropdown);
    this.wrapper = document.querySelector(cfg.wrapper);

    this.dropdownIcon = this.wrapper.querySelector('.dropdown-menu-toggle-icon');
    this.loadingIcon = loadingIconForLegacyJS({ classes: ['gl-display-none'] });
    this.dropdown.appendChild(this.loadingIcon);
    this.dropdownToggleText = this.wrapper.querySelector('.dropdown-toggle-text');

    this.initDropdown();
    this.selectInitialTemplate();
  }

  selectInitialTemplate() {
    const template = this.dropdown.dataset.selected;

    if (!template) {
      return;
    }

    this.mediator.selectTemplateFile(this, template);
  }

  show() {
    if (this.dropdown === null) {
      this.init();
    }

    this.wrapper.classList.remove('hidden');

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
      this.dropdown.focus();
    }, 0);
  }

  hide() {
    if (this.dropdown !== null) {
      this.wrapper.classList.add('hidden');
    }
  }

  isHidden() {
    return !this.wrapper || this.wrapper.classList.contains('hidden');
  }

  getToggleText() {
    return this.dropdownToggleText.textContent;
  }

  setToggleText(text) {
    this.dropdownToggleText.textContent = text;
  }

  renderLoading() {
    this.loadingIcon.classList.remove('gl-display-none');
    this.dropdownIcon.classList.add('gl-display-none');
  }

  renderLoaded() {
    this.loadingIcon.classList.add('gl-display-none');
    this.dropdownIcon.classList.remove('gl-display-none');
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
