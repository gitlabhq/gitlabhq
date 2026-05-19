import autosize from 'autosize';
import GfmAutoComplete, {
  defaultAutocompleteConfig,
  getEnableGFMType,
} from 'ee_else_ce/gfm_auto_complete';
import { disableButtonIfEmptyField } from '~/lib/utils/common_utils';
import dropzoneInput from './dropzone_input';
import { addMarkdownListeners, removeMarkdownListeners } from './lib/utils/text_markdown';

const glFormInstances = new WeakMap();

export default class GLForm {
  /**
   * Create a GLForm
   *
   * @param {jQuery|HTMLElement} form Root element of the GLForm (jQuery object or DOM element)
   * @param {Object} enableGFM Which autocomplete features should be enabled?
   * @param {Boolean} forceNew If true, treat the element as a **new** form even if `gfm-form` class already exists.
   * @param {Object} gfmDataSources The paths of the autocomplete data sources to use for GfmAutoComplete
   *                                By default, the backend embeds these in the global object gl.GfmAutocomplete.dataSources.
   *                                Use this param to override them.
   */
  // eslint-disable-next-line max-params
  constructor(form, enableGFM = {}, forceNew = false, gfmDataSources = {}) {
    // Support both jQuery objects and native DOM elements
    this.form = form?.jquery ? form[0] : form;

    if (!this.form) {
      return;
    }

    this.textarea = this.form.querySelector('textarea.js-gfm-input');
    this.enableGFM = { ...defaultAutocompleteConfig, ...enableGFM };
    this.isManuallyResizing = false;

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
    glFormInstances.set(this.form, this);

    // Set window variable from RTE
    const editorElement = this.textarea?.closest('.js-editor');
    if (editorElement?.dataset?.gfmEditorMinHeight) {
      this.textarea.style.minHeight = editorElement.dataset.gfmEditorMinHeight;
    }
  }

  static getDataSources(gfmDataSources) {
    if (Object.keys(gfmDataSources).length > 0) {
      return gfmDataSources;
    }
    return (gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources) || {};
  }

  static getInstance(form) {
    if (!form) return null;
    const element = form?.jquery ? form[0] : form;
    return glFormInstances.get(element);
  }

  filterEnabledGFM(dataSources) {
    for (const [item, enabled] of Object.entries(this.enableGFM)) {
      if (
        enabled &&
        item !== 'emojis' &&
        item !== 'types' &&
        !dataSources[getEnableGFMType(item)]
      ) {
        this.enableGFM[item] = false;
      }
    }
  }

  destroy() {
    if (!this.form) {
      return;
    }

    // Clean form listeners
    this.clearEventListeners();

    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
      this.resizeObserver = null;
    }

    // Clean up components
    this.autoComplete?.destroy();
    this.formDropzone?.destroy();

    glFormInstances.delete(this.form);
  }

  setupForm(dataSources, forceNew = false) {
    const isNewForm = !this.form.classList.contains('gfm-form') || forceNew;
    this.form.classList.remove('js-new-note-form');

    if (isNewForm) {
      this.initializeNewForm(dataSources);
    }

    // form and textarea event listeners
    this.addEventListeners();
    addMarkdownListeners(this.form);
    // Forms may be hidden via inline style (e.g., when cloned and inserted dynamically).
    // Clearing the display style restores default visibility, matching jQuery's .show() behavior.
    this.form.style.display = '';

    if (this.textarea?.dataset?.autofocus === 'true') {
      this.textarea.focus();
    }
  }

  initializeNewForm(dataSources) {
    const existingDropzone = this.form.querySelector('.div-dropzone');
    if (existingDropzone) {
      existingDropzone.remove();
    }
    this.form.classList.add('gfm-form');

    // remove notify commit author checkbox for non-commit notes
    disableButtonIfEmptyField(
      this.form.querySelector('.js-note-text'),
      '.js-comment-button, .js-note-new-discussion',
    );

    this.autoComplete = new GfmAutoComplete(dataSources);
    this.autoComplete.setup(this.form.querySelector('.js-gfm-input'), this.enableGFM);
    this.formDropzone = dropzoneInput(this.form, { parallelUploads: 1 });

    if (!this.form.classList.contains('js-no-autosize')) {
      autosize(this.textarea);
    }
  }

  updateAutocompleteDataSources(dataSources) {
    if (this.autoComplete) {
      this.autoComplete.updateDataSources(dataSources);
    }
  }

  clearEventListeners() {
    if (this.textarea) {
      this.textarea.removeEventListener('focus', this.handleFocus);
      this.textarea.removeEventListener('blur', this.handleBlur);
      this.textarea.removeEventListener('mousedown', this.handleManualResize);
      this.textarea.removeEventListener('mouseup', this.handleManualResizeUp);
    }

    if (this.form) {
      removeMarkdownListeners(this.form);
    }
  }

  addEventListeners() {
    if (this.textarea) {
      this.textarea.addEventListener('focus', this.handleFocus);
      this.textarea.addEventListener('blur', this.handleBlur);
      this.textarea.addEventListener('mousedown', this.handleManualResize);
    }
  }

  handleFocus() {
    const mdArea = this.textarea.closest('.md-area');
    if (mdArea) {
      mdArea.classList.add('is-focused');
    }
  }

  handleBlur() {
    const mdArea = this.textarea.closest('.md-area');
    if (mdArea) {
      mdArea.classList.remove('is-focused');
    }
  }

  handleManualResize(e) {
    const mdArea = this.textarea.closest('.md-area');
    const textareaElement = mdArea?.querySelector('textarea');
    if (!textareaElement) return;

    const rect = textareaElement.getBoundingClientRect();
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
      this.textarea.style.minHeight = null;
      const editorElement = this.textarea.closest('.js-editor');
      if (editorElement) {
        editorElement.dataset.gfmEditorMinHeight = null;
      }

      this.textarea.addEventListener('mouseup', this.handleManualResizeUp);
    }
  }

  handleManualResizeUp() {
    // Set current height as min height, so autogrow will still work
    if (this.textarea) {
      const editorHeight = `${this.textarea.offsetHeight}px`;
      this.textarea.style.minHeight = editorHeight;
      // Store min height in global variable for RTE
      const editorElement = this.textarea.closest('.js-editor');
      if (editorElement) {
        editorElement.dataset.gfmEditorMinHeight = editorHeight;
      }
    }

    this.textarea.removeEventListener('mouseup', this.handleManualResizeUp);
  }

  get supportsQuickActions() {
    return this.textarea?.dataset?.supportsQuickActions === 'true';
  }
}
