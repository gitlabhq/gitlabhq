import $ from 'jquery';
import autosize from 'autosize';
import GfmAutoComplete from './gfm_auto_complete';
import dropzoneInput from './dropzone_input';
import { addMarkdownListeners, removeMarkdownListeners } from './lib/utils/text_markdown';

export default class GLForm {
  constructor(form, enableGFM = false) {
    this.form = form;
    this.textarea = this.form.find('textarea.js-gfm-input');
    this.enableGFM = enableGFM;
    // Before we start, we should clean up any previous data for this form
    this.destroy();
    // Setup the form
    this.setupForm();
    this.form.data('glForm', this);
  }

  destroy() {
    // Clean form listeners
    this.clearEventListeners();
    if (this.autoComplete) {
      this.autoComplete.destroy();
    }
    this.form.data('glForm', null);
  }

  setupForm() {
    const isNewForm = this.form.is(':not(.gfm-form)');
    this.form.removeClass('js-new-note-form');
    if (isNewForm) {
      this.form.find('.div-dropzone').remove();
      this.form.addClass('gfm-form');
      // remove notify commit author checkbox for non-commit notes
      gl.utils.disableButtonIfEmptyField(this.form.find('.js-note-text'), this.form.find('.js-comment-button, .js-note-new-discussion'));
      this.autoComplete = new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources);
      this.autoComplete.setup(this.form.find('.js-gfm-input'), {
        emojis: true,
        members: this.enableGFM,
        issues: this.enableGFM,
        milestones: this.enableGFM,
        mergeRequests: this.enableGFM,
        labels: this.enableGFM,
      });
      dropzoneInput(this.form);
      autosize(this.textarea);
    }
    // form and textarea event listeners
    this.addEventListeners();
    addMarkdownListeners(this.form);
    // hide discard button
    this.form.find('.js-note-discard').hide();
    this.form.show();
    if (this.isAutosizeable) this.setupAutosize();
  }

  setupAutosize() {
    this.textarea.off('autosize:resized')
      .on('autosize:resized', this.setHeightData.bind(this));

    this.textarea.off('mouseup.autosize')
      .on('mouseup.autosize', this.destroyAutosize.bind(this));

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
    this.textarea.off('focus');
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
}
