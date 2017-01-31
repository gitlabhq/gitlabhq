/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, no-new, max-len */
/* global GitLab */
/* global DropzoneInput */
/* global autosize */

(() => {
  const global = window.gl || (window.gl = {});

  function GLForm(form) {
    this.form = form;
    this.textarea = this.form.find('textarea.js-gfm-input');
    // Before we start, we should clean up any previous data for this form
    this.destroy();
    // Setup the form
    this.setupForm();
    this.form.data('gl-form', this);
  }

  GLForm.prototype.destroy = function() {
    // Clean form listeners
    this.clearEventListeners();
    return this.form.data('gl-form', null);
  };

  GLForm.prototype.setupForm = function() {
    var isNewForm;
    isNewForm = this.form.is(':not(.gfm-form)');
    this.form.removeClass('js-new-note-form');
    if (isNewForm) {
      this.form.find('.div-dropzone').remove();
      this.form.addClass('gfm-form');
      // remove notify commit author checkbox for non-commit notes
      gl.utils.disableButtonIfEmptyField(this.form.find('.js-note-text'), this.form.find('.js-comment-button'));
      gl.GfmAutoComplete.setup(this.form.find('.js-gfm-input'));
      new DropzoneInput(this.form);
      autosize(this.textarea);
      // form and textarea event listeners
      this.addEventListeners();
    }
    gl.text.init(this.form);
    // hide discard button
    this.form.find('.js-note-discard').hide();
    this.form.show();
    if (this.isAutosizeable) this.setupAutosize();
  };

  GLForm.prototype.setupAutosize = function () {
    this.textarea.off('autosize:resized')
      .on('autosize:resized', this.setHeightData.bind(this));

    this.textarea.off('mouseup.autosize')
      .on('mouseup.autosize', this.destroyAutosize.bind(this));

    setTimeout(() => {
      autosize(this.textarea);
      this.textarea.css('resize', 'vertical');
    }, 0);
  };

  GLForm.prototype.setHeightData = function () {
    this.textarea.data('height', this.textarea.outerHeight());
  };

  GLForm.prototype.destroyAutosize = function () {
    const outerHeight = this.textarea.outerHeight();

    if (this.textarea.data('height') === outerHeight) return;

    autosize.destroy(this.textarea);

    this.textarea.data('height', outerHeight);
    this.textarea.outerHeight(outerHeight);
    this.textarea.css('max-height', window.outerHeight);
  };

  GLForm.prototype.clearEventListeners = function() {
    this.textarea.off('focus');
    this.textarea.off('blur');
    return gl.text.removeListeners(this.form);
  };

  GLForm.prototype.addEventListeners = function() {
    this.textarea.on('focus', function() {
      return $(this).closest('.md-area').addClass('is-focused');
    });
    return this.textarea.on('blur', function() {
      return $(this).closest('.md-area').removeClass('is-focused');
    });
  };

  global.GLForm = GLForm;
})();
