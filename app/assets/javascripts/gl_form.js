import autosize from 'autosize';
import GfmAutoComplete, {
  defaultAutocompleteConfig,
  getEnableGFMType,
} from 'ee_else_ce/gfm_auto_complete';
import { disableButtonIfEmptyField } from '~/lib/utils/common_utils';
import dropzoneInput from './dropzone_input';
import { addMarkdownListeners, removeMarkdownListeners } from './lib/utils/text_markdown';

export default class GLForm {
  /**
   * Create a GLForm
   *
   * @param {jQuery} form Root element of the GLForm
   * @param {Object} enableGFM Which autocomplete features should be enabled?
   * @param {Boolean} forceNew If true, treat the element as a **new** form even if `gfm-form` class already exists.
   * @param {Object} gfmDataSources The paths of the autocomplete data sources to use for GfmAutoComplete
   *                                By default, the backend embeds these in the global object gl.GfmAutocomplete.dataSources.
   *                                Use this param to override them.
   */
  // eslint-disable-next-line max-params
  constructor(form, enableGFM = {}, forceNew = false, gfmDataSources = {}) {
    this.form = form;
    this.textarea = this.form.find('textarea.js-gfm-input');
    this.enableGFM = { ...defaultAutocompleteConfig, ...enableGFM };
    this.isManuallyResizing = false;

    // Cache DOM elements
    [this.textareaElement] = this.textarea;

    // Bind methods once to avoid repeated binding
    this.handleFocus = this.handleFocus.bind(this);
    this.handleBlur = this.handleBlur.bind(this);
    this.handleManualResize = this.handleManualResize.bind(this);
    this.handleManualResizeUp = this.handleManualResizeUp.bind(this);

    // Get data sources more efficiently
    const dataSources = GLForm.getDataSources(gfmDataSources);
    this.filterEnabledGFM(dataSources);

    // Before we start, we should clean up any previous data for this form
    this.destroy();

    // Set up the form
    this.setupForm(dataSources, forceNew);
    this.form.data('glForm', this);

    // Set window variable from RTE
    if (this.textarea[0]?.closest('.js-editor')?.dataset?.gfmEditorMinHeight) {
      this.textarea[0].style.minHeight =
        this.textarea[0].closest('.js-editor').dataset.gfmEditorMinHeight;
    }
  }

  static getDataSources(gfmDataSources) {
    if (Object.keys(gfmDataSources).length > 0) {
      return gfmDataSources;
    }
    return (gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources) || {};
  }

  filterEnabledGFM(dataSources) {
    for (const [item, enabled] of Object.entries(this.enableGFM)) {
      if (enabled && item !== 'emojis' && !dataSources[getEnableGFMType(item)]) {
        this.enableGFM[item] = false;
      }
    }
  }

  destroy() {
    // Clean form listeners
    this.clearEventListeners();

    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
      this.resizeObserver = null;
    }

    // Clean up components
    this.autoComplete?.destroy();
    this.formDropzone?.destroy();

    this.form.data('glForm', null);
  }

  setupForm(dataSources, forceNew = false) {
    const isNewForm = this.form.is(':not(.gfm-form)') || forceNew;
    this.form.removeClass('js-new-note-form');

    if (isNewForm) {
      this.initializeNewForm(dataSources);
    }

    // form and textarea event listeners
    this.addEventListeners();
    addMarkdownListeners(this.form);
    this.form.show();

    if (this.textarea.data('autofocus') === true) {
      this.textarea.focus();
    }
  }

  initializeNewForm(dataSources) {
    this.form.find('.div-dropzone').remove();
    this.form.addClass('gfm-form');

    // remove notify commit author checkbox for non-commit notes
    disableButtonIfEmptyField(
      this.form.find('.js-note-text'),
      this.form.find('.js-comment-button, .js-note-new-discussion'),
    );

    this.autoComplete = new GfmAutoComplete(dataSources);
    this.autoComplete.setup(this.form.find('.js-gfm-input'), this.enableGFM);
    this.formDropzone = dropzoneInput(this.form, { parallelUploads: 1 });

    if (this.form.is(':not(.js-no-autosize)')) {
      autosize(this.textarea);
    }
  }

  updateAutocompleteDataSources(dataSources) {
    if (this.autoComplete) {
      this.autoComplete.updateDataSources(dataSources);
    }
  }

  clearEventListeners() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.textarea.off('focus');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.textarea.off('blur');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.textarea.off('mousedown');

    removeMarkdownListeners(this.form);
  }

  addEventListeners() {
    this.textarea.on('focus', this.handleFocus);
    this.textarea.on('blur', this.handleBlur);
    this.textarea.on('mousedown', this.handleManualResize);
  }

  handleFocus() {
    this.textarea.closest('.md-area').addClass('is-focused');
  }

  handleBlur() {
    this.textarea.closest('.md-area').removeClass('is-focused');
  }

  handleManualResize(e) {
    const textarea = this.textarea.closest('.md-area textarea')[0];
    const rect = textarea.getBoundingClientRect();
    const mouseX = e.clientX;
    const mouseY = e.clientY;
    const cornerSize = 16;
    const isInBottomRight =
      mouseX >= rect.right - cornerSize &&
      mouseX <= rect.right &&
      mouseY >= rect.bottom - cornerSize &&
      mouseY <= rect.bottom;

    if (isInBottomRight) {
      this.isManuallyResizing = true;
      this.textarea[0].style.minHeight = null;
      this.textarea[0].closest('.js-editor').dataset.gfmEditorMinHeight = null;

      this.textarea.on('mouseup', this.handleManualResizeUp);
    }
  }

  handleManualResizeUp() {
    // Set current height as min height, so autogrow will still work
    if (this.textarea[0]) {
      const editorHeight = `${this.textarea[0].offsetHeight}px`;
      this.textarea[0].style.minHeight = editorHeight;
      // Store min height in global variable for RTE
      this.textarea[0].closest('.js-editor').dataset.gfmEditorMinHeight = editorHeight;
    }

    // eslint-disable-next-line @gitlab/no-global-event-off
    this.textarea.off('mouseup');
  }

  get supportsQuickActions() {
    return Boolean(this.textarea.data('supports-quick-actions'));
  }
}
