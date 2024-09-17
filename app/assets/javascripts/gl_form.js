import autosize from 'autosize';
import $ from 'jquery';
import { isEmpty } from 'lodash';
import GfmAutoComplete, { defaultAutocompleteConfig } from 'ee_else_ce/gfm_auto_complete';
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

    // Disable autocomplete for keywords which do not have dataSources available
    let dataSources = (gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources) || {};

    if (!isEmpty(gfmDataSources)) {
      dataSources = gfmDataSources;
    }

    Object.keys(this.enableGFM).forEach((item) => {
      if (item !== 'emojis' && !dataSources[item]) {
        this.enableGFM[item] = false;
      }
    });

    // Before we start, we should clean up any previous data for this form
    this.destroy();
    // Set up the form
    this.setupForm(dataSources, forceNew);
    this.form.data('glForm', this);
  }

  destroy() {
    // Clean form listeners
    this.clearEventListeners();
    if (this.autoComplete) {
      this.autoComplete.destroy();
    }
    if (this.formDropzone) {
      this.formDropzone.destroy();
    }

    this.form.data('glForm', null);
  }

  setupForm(dataSources, forceNew = false) {
    const isNewForm = this.form.is(':not(.gfm-form)') || forceNew;
    this.form.removeClass('js-new-note-form');
    if (isNewForm) {
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
    // form and textarea event listeners
    this.addEventListeners();
    addMarkdownListeners(this.form);
    this.form.show();
    if (this.isAutosizeable) this.setupAutosize();
    if (this.textarea.data('autofocus') === true) this.textarea.focus();
  }

  updateAutocompleteDataSources(dataSources) {
    if (this.autoComplete) {
      this.autoComplete.updateDataSources(dataSources);
    }
  }

  setupAutosize() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.textarea.off('autosize:resized').on('autosize:resized', this.setHeightData.bind(this));

    // eslint-disable-next-line @gitlab/no-global-event-off
    this.textarea.off('mouseup.autosize').on('mouseup.autosize', this.destroyAutosize.bind(this));

    setTimeout(() => {
      autosize(this.textarea);
      this.textarea.css('resize', 'vertical');
    }, 0);
  }

  setHeightData() {
    this.textarea.data('height', this.textarea.outerHeight());
  }

  destroyAutosize() {
    const outerHeight = this.textarea.outerHeight();

    if (this.textarea.data('height') === outerHeight) return;

    autosize.destroy(this.textarea);

    this.textarea.data('height', outerHeight);
    this.textarea.outerHeight(outerHeight);
    this.textarea.css('max-height', window.outerHeight);
  }

  clearEventListeners() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.textarea.off('focus');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.textarea.off('blur');
    removeMarkdownListeners(this.form);
  }

  addEventListeners() {
    this.textarea.on('focus', function focusTextArea() {
      $(this).closest('.md-area').addClass('is-focused');
    });
    this.textarea.on('blur', function blurTextArea() {
      $(this).closest('.md-area').removeClass('is-focused');
    });
  }

  get supportsQuickActions() {
    return Boolean(this.textarea.data('supports-quick-actions'));
  }
}
