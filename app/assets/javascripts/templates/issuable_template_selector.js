/* eslint-disable no-useless-return, max-len */

import $ from 'jquery';
import Api from '../api';
import TemplateSelector from '../blob/template_selector';

export default class IssuableTemplateSelector extends TemplateSelector {
  constructor(...args) {
    super(...args);
    this.projectPath = this.dropdown.data('projectPath');
    this.namespacePath = this.dropdown.data('namespacePath');
    this.issuableType = this.$dropdownContainer.data('issuableType');
    this.titleInput = $(`#${this.issuableType}_title`);

    const initialQuery = {
      name: this.dropdown.data('selected'),
    };

    if (initialQuery.name) this.requestFile(initialQuery);

    $('.reset-template', this.dropdown.parent()).on('click', () => {
      this.setInputValueToTemplateContent();
    });

    $('.no-template', this.dropdown.parent()).on('click', () => {
      this.currentTemplate.content = '';
      this.setInputValueToTemplateContent();
      $('.dropdown-toggle-text', this.dropdown).text('Choose a template');
    });
  }

  requestFile(query) {
    this.startLoadingSpinner();
    Api.issueTemplate(this.namespacePath, this.projectPath, query.name, this.issuableType, (err, currentTemplate) => {
      this.currentTemplate = currentTemplate;
      this.stopLoadingSpinner();
      if (err) return; // Error handled by global AJAX error handler
      this.setInputValueToTemplateContent();
    });
    return;
  }

  setInputValueToTemplateContent() {
    // `this.setEditorContent` sets the value of the description input field
    // to the content of the template selected.
    if (this.titleInput.val() === '') {
      // If the title has not yet been set, focus the title input and
      // skip focusing the description input by setting `true` as the
      // `skipFocus` option to `setEditorContent`.
      this.setEditorContent(this.currentTemplate, { skipFocus: true });
      this.titleInput.focus();
    } else {
      this.setEditorContent(this.currentTemplate, { skipFocus: false });
    }
    return;
  }
}
