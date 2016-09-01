/*= require ../blob/template_selector */

((global) => {
  class IssuableTemplateSelector extends TemplateSelector {
    constructor(...args) {
      super(...args);
      this.projectPath = this.dropdown.data('project-path');
      this.namespacePath = this.dropdown.data('namespace-path');
      this.issuableType = this.wrapper.data('issuable-type');
      this.titleInput = $(`#${this.issuableType}_title`);

      let initialQuery = {
        name: this.dropdown.data('selected')
      };

      if (initialQuery.name) this.requestFile(initialQuery);

      $('.reset-template', this.dropdown.parent()).on('click', () => {
        if (this.currentTemplate) this.setInputValueToTemplateContent(false);
      });
    }

    requestFile(query) {
      this.startLoadingSpinner();
      Api.issueTemplate(this.namespacePath, this.projectPath, query.name, this.issuableType, (err, currentTemplate) => {
        this.currentTemplate = currentTemplate;
        if (err) return; // Error handled by global AJAX error handler
        this.stopLoadingSpinner();
        this.setInputValueToTemplateContent(true);
      });
      return;
    }

    setInputValueToTemplateContent(append) {
      // `this.requestFileSuccess` sets the value of the description input field
      // to the content of the template selected. If `append` is true, the
      // template content will be appended to the previous value of the field,
      // separated by a blank line if the previous value is non-empty.
      if (this.titleInput.val() === '') {
        // If the title has not yet been set, focus the title input and
        // skip focusing the description input by setting `true` as the
        // `skipFocus` option to `requestFileSuccess`.
        this.requestFileSuccess(this.currentTemplate, {skipFocus: true, append});
        this.titleInput.focus();
      } else {
        this.requestFileSuccess(this.currentTemplate, {skipFocus: false, append});
      }
      return;
    }
  }

  global.IssuableTemplateSelector = IssuableTemplateSelector;
})(window);
