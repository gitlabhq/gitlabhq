import $ from 'jquery';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';

export default class LegacyTemplateSelector {
  constructor({ dropdown, data, pattern, wrapper, editor, $input } = {}) {
    this.pattern = pattern;
    this.editor = editor;
    this.dropdown = dropdown;
    this.$dropdownContainer = wrapper;
    this.$filenameInput = $input || $('#file_name');
    this.dropdownIcon = dropdown[0].querySelector('.dropdown-menu-toggle-icon');
    this.loadingIcon = loadingIconForLegacyJS({ classes: ['gl-hidden'] });
    this.dropdownIcon.parentNode.insertBefore(this.loadingIcon, this.dropdownIcon.nextSibling);

    this.initDropdown(dropdown, data);
    this.listenForFilenameInput();
    this.renderMatchedDropdown();
    this.initAutosizeUpdateEvent();
  }

  initDropdown(dropdown, data) {
    return initDeprecatedJQueryDropdown($(dropdown), {
      data,
      filterable: true,
      selectable: true,
      toggleLabel: (item) => item.name,
      search: {
        fields: ['name'],
      },
      clicked: (options) => this.onDropdownClicked(options),
      text: (item) => item.name,
    });
  }

  // Subclasses can override this method to conditionally prevent fetching file templates
  onDropdownClicked(options) {
    this.fetchFileTemplate(options);
  }

  initAutosizeUpdateEvent() {
    this.autosizeUpdateEvent = document.createEvent('Event');
    this.autosizeUpdateEvent.initEvent('autosize:update', true, false);
  }

  listenForFilenameInput() {
    return this.$filenameInput.on('keyup blur', (e) => this.renderMatchedDropdown(e));
  }

  renderMatchedDropdown() {
    if (!this.$filenameInput.length) {
      return null;
    }

    const filenameMatches = this.pattern.test(this.$filenameInput.val().trim());

    if (!filenameMatches) {
      return this.$dropdownContainer.addClass('hidden');
    }
    return this.$dropdownContainer.removeClass('hidden');
  }

  fetchFileTemplate(options) {
    const { e } = options;
    const item = options.selectedObj;

    e.preventDefault();
    return this.requestFile(item);
  }

  // eslint-disable-next-line class-methods-use-this
  requestFile() {
    // This `requestFile` method is an abstract method that should
    // be added by all subclasses.
  }

  setEditorContent(file, { skipFocus } = {}) {
    if (!file) return;

    let newValue = file.content;

    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('issue[description]')) {
      newValue += `\n${urlParams.get('issue[description]')}`;
    }

    this.editor.setValue(newValue, 1);

    if (!skipFocus) this.editor.focus();

    if (this.editor instanceof $) {
      this.editor.get(0).dispatchEvent(this.autosizeUpdateEvent);
      this.editor.trigger('input');
    }
  }

  getEditorContent() {
    return this.editor.getValue();
  }

  startLoadingSpinner() {
    this.loadingIcon.classList.remove('gl-hidden');
    this.dropdownIcon.classList.add('gl-hidden');
  }

  stopLoadingSpinner() {
    this.loadingIcon.classList.add('gl-hidden');
    this.dropdownIcon.classList.remove('gl-hidden');
  }
}
