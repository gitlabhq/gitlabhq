/* eslint-disable no-useless-return */

import $ from 'jquery';
import { __ } from '~/locale';
import Api from '../api';
import TemplateSelector from '../blob/template_selector';

export default class IssuableTemplateSelector extends TemplateSelector {
  constructor(...args) {
    super(...args);

    this.projectId = this.dropdown.data('projectId');
    this.issuableType = this.$dropdownContainer.data('issuableType');
    this.titleInput = $(`#${this.issuableType}_title`);
    this.templateWarningEl = $('.js-issuable-template-warning');
    this.warnTemplateOverride = args[0].warnTemplateOverride;

    const initialQuery = {
      name: this.dropdown.data('selected'),
    };

    if (initialQuery.name) this.requestFile(initialQuery);

    $('.reset-template', this.dropdown.parent()).on('click', () => {
      this.setInputValueToTemplateContent();
    });

    $('.no-template', this.dropdown.parent()).on('click', () => {
      this.reset();
    });

    this.templateWarningEl.find('.js-close-btn').on('click', () => {
      // Explicitly check against 0 value
      if (this.previousSelectedIndex !== undefined) {
        this.dropdown.data('deprecatedJQueryDropdown').selectRowAtIndex(this.previousSelectedIndex);
      } else {
        this.reset();
      }

      this.templateWarningEl.addClass('hidden');
    });

    this.templateWarningEl.find('.js-override-template').on('click', () => {
      this.requestFile(this.overridingTemplate);
      this.setSelectedIndex();

      this.templateWarningEl.addClass('hidden');
      this.overridingTemplate = null;
    });
  }

  reset() {
    if (this.currentTemplate) {
      this.currentTemplate.content = '';
    }

    this.setInputValueToTemplateContent();
    $('.dropdown-toggle-text', this.dropdown).text(__('Choose a template'));
    this.previousSelectedIndex = null;
  }

  setSelectedIndex() {
    this.previousSelectedIndex = this.dropdown.data('deprecatedJQueryDropdown').selectedIndex;
  }

  onDropdownClicked(query) {
    const content = this.getEditorContent();
    const isContentUnchanged =
      content === '' || (this.currentTemplate && content === this.currentTemplate.content);

    if (!this.warnTemplateOverride || isContentUnchanged) {
      super.onDropdownClicked(query);
      this.setSelectedIndex();

      return;
    }

    this.overridingTemplate = query.selectedObj;
    this.templateWarningEl.removeClass('hidden');
  }

  requestFile(query) {
    const callback = (currentTemplate) => {
      this.currentTemplate = currentTemplate;
      this.stopLoadingSpinner();
      this.setInputValueToTemplateContent();
    };

    this.startLoadingSpinner();

    Api.projectTemplate(
      this.projectId,
      this.issuableType,
      query.name,
      { source_template_project_id: query.project_id },
      callback,
    );
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
