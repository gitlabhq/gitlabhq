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
        if (this.currentTemplate) this.setInputValueToTemplateContent();
      });
    }

    requestFile(query) {
      this.startLoadingSpinner();
      Api.issueTemplate(this.namespacePath, this.projectPath, query.name, this.issuableType, (err, currentTemplate) => {
        this.currentTemplate = currentTemplate;
        if (err) return; // Error handled by global AJAX error handler
        this.stopLoadingSpinner();
        this.setInputValueToTemplateContent();
      });
      return;
    }

    setInputValueToTemplateContent() {
      // `this.requestFileSuccess` sets the value of the description input field
      // to the content of the template selected.
      if (this.titleInput.val() === '') {
        // If the title has not yet been set, focus the title input and
        // skip focusing the description input by setting `true` as the 2nd
        // argument to `requestFileSuccess`.
        this.requestFileSuccess(this.currentTemplate, true);
        this.titleInput.focus();
      } else {
        this.requestFileSuccess(this.currentTemplate);
      }
      return;
    }
  }

  global.IssuableTemplateSelector = IssuableTemplateSelector;
})(window);
