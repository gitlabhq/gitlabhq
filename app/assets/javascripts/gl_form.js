(function() {
  this.GLForm = (function() {
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
        disableButtonIfEmptyField(this.form.find('.js-note-text'), this.form.find('.js-comment-button'));
        // remove notify commit author checkbox for non-commit notes
        GitLab.GfmAutoComplete.setup(this.form.find('.js-gfm-input'));
        new DropzoneInput(this.form);
        autosize(this.textarea);
        // form and textarea event listeners
        this.addEventListeners();
        gl.text.init(this.form);
      }
      // hide discard button
      this.form.find('.js-note-discard').hide();
      return this.form.show();
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

    return GLForm;

  })();

  window.gl.Dispatcher.register([
    'projects:milestones:edit',
    'projects:milestones:new'
  ], () => new GLForm($('.milestone-form')));

  window.gl.Dispatcher.register([
    'projects:issues:new',
    'projects:issues:edit'
  ], () => new GLForm($('.issue-form')));

  window.gl.Dispatcher.register([
    'projects:merge_requests:new',
    'projects:merge_requests:edit'
  ], () => new GLForm($('.merge-request-form')));

  window.gl.Dispatcher.register('projects:tags:new', () => new GLForm($('.tag-form')));

  window.gl.Dispatcher.register('projects:releases:edit', () => new GLForm($('.release-form')));

  window.gl.Dispatcher.register('projects:wikis:*', () => new GLForm($('.wiki-form')));

}).call(this);
