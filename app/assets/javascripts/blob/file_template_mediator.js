/* eslint-disable class-methods-use-this */

import $ from 'jquery';
import Flash from '../flash';
import FileTemplateTypeSelector from './template_selectors/type_selector';
import BlobCiYamlSelector from './template_selectors/ci_yaml_selector';
import DockerfileSelector from './template_selectors/dockerfile_selector';
import GitignoreSelector from './template_selectors/gitignore_selector';
import LicenseSelector from './template_selectors/license_selector';

export default class FileTemplateMediator {
  constructor({ editor, currentAction }) {
    this.editor = editor;
    this.currentAction = currentAction;

    this.initTemplateSelectors();
    this.initTemplateTypeSelector();
    this.initDomElements();
    this.initDropdowns();
    this.initPageEvents();
  }

  initTemplateSelectors() {
    // Order dictates template type dropdown item order
    this.templateSelectors = [
      GitignoreSelector,
      BlobCiYamlSelector,
      DockerfileSelector,
      LicenseSelector,
    ].map(TemplateSelectorClass => new TemplateSelectorClass({ mediator: this }));
  }

  initTemplateTypeSelector() {
    this.typeSelector = new FileTemplateTypeSelector({
      mediator: this,
      dropdownData: this.templateSelectors
        .map((templateSelector) => {
          const cfg = templateSelector.config;

          return {
            name: cfg.name,
            key: cfg.key,
          };
        }),
    });
  }

  initDomElements() {
    const $templatesMenu = $('.template-selectors-menu');
    const $undoMenu = $templatesMenu.find('.template-selectors-undo-menu');
    const $fileEditor = $('.file-editor');

    this.$templatesMenu = $templatesMenu;
    this.$undoMenu = $undoMenu;
    this.$undoBtn = $undoMenu.find('button');
    this.$templateSelectors = $templatesMenu.find('.template-selector-dropdowns-wrap');
    this.$filenameInput = $fileEditor.find('.js-file-path-name-input');
    this.$fileContent = $fileEditor.find('#file-content');
    this.$commitForm = $fileEditor.find('form');
    this.$navLinks = $fileEditor.find('.nav-links');
  }

  initDropdowns() {
    if (this.currentAction === 'create') {
      this.typeSelector.show();
    } else {
      this.hideTemplateSelectorMenu();
    }

    this.displayMatchedTemplateSelector();
  }

  initPageEvents() {
    this.listenForFilenameInput();
    this.prepFileContentForSubmit();
    this.listenForPreviewMode();
  }

  listenForFilenameInput() {
    this.$filenameInput.on('keyup blur', () => {
      this.displayMatchedTemplateSelector();
    });
  }

  prepFileContentForSubmit() {
    this.$commitForm.submit(() => {
      this.$fileContent.val(this.editor.getValue());
    });
  }

  listenForPreviewMode() {
    this.$navLinks.on('click', 'a', (e) => {
      const urlPieces = e.target.href.split('#');
      const hash = urlPieces[1];
      if (hash === 'preview') {
        this.hideTemplateSelectorMenu();
      } else if (hash === 'editor') {
        this.showTemplateSelectorMenu();
      }
    });
  }

  selectTemplateType(item, e) {
    if (e) {
      e.preventDefault();
    }

    this.templateSelectors.forEach((selector) => {
      if (selector.config.key === item.key) {
        selector.show();
      } else {
        selector.hide();
      }
    });

    this.typeSelector.setToggleText(item.name);

    this.cacheToggleText();
  }

  selectTemplateTypeOptions(options) {
    this.selectTemplateType(options.selectedObj, options.e);
  }

  selectTemplateFile(selector, query, data) {
    selector.renderLoading();
    // in case undo menu is already already there
    this.destroyUndoMenu();
    this.fetchFileTemplate(selector.config.endpoint, query, data)
      .then((file) => {
        this.showUndoMenu();
        this.setEditorContent(file);
        this.setFilename(selector.config.name);
        selector.renderLoaded();
      })
      .catch(err => new Flash(`An error occurred while fetching the template: ${err}`));
  }

  displayMatchedTemplateSelector() {
    const currentInput = this.getFilename();
    this.templateSelectors.forEach((selector) => {
      const match = selector.config.pattern.test(currentInput);

      if (match) {
        this.typeSelector.show();
        this.selectTemplateType(selector.config);
        this.showTemplateSelectorMenu();
      }
    });
  }

  fetchFileTemplate(apiCall, query, data) {
    return new Promise((resolve) => {
      const resolveFile = file => resolve(file);

      if (!data) {
        apiCall(query, resolveFile);
      } else {
        apiCall(query, data, resolveFile);
      }
    });
  }

  setEditorContent(file) {
    if (!file && file !== '') return;

    const newValue = file.content || file;

    this.editor.setValue(newValue, 1);

    this.editor.focus();

    this.editor.navigateFileStart();
  }

  findTemplateSelectorByKey(key) {
    return this.templateSelectors.find(selector => selector.config.key === key);
  }

  showUndoMenu() {
    this.$undoMenu.removeClass('hidden');

    this.$undoBtn.on('click', () => {
      this.restoreFromCache();
      this.destroyUndoMenu();
    });
  }

  destroyUndoMenu() {
    this.cacheFileContents();
    this.cacheToggleText();
    this.$undoMenu.addClass('hidden');
    this.$undoBtn.off('click');
  }

  hideTemplateSelectorMenu() {
    this.$templatesMenu.hide();
  }

  showTemplateSelectorMenu() {
    this.$templatesMenu.show();
  }

  cacheToggleText() {
    this.cachedToggleText = this.getTemplateSelectorToggleText();
  }

  cacheFileContents() {
    this.cachedContent = this.editor.getValue();
    this.cachedFilename = this.getFilename();
  }

  restoreFromCache() {
    this.setEditorContent(this.cachedContent);
    this.setFilename(this.cachedFilename);
    this.setTemplateSelectorToggleText();
  }

  getTemplateSelectorToggleText() {
    return this.$templateSelectors
      .find('.js-template-selector-wrap:visible .dropdown-toggle-text')
      .text();
  }

  setTemplateSelectorToggleText() {
    return this.$templateSelectors
      .find('.js-template-selector-wrap:visible .dropdown-toggle-text')
      .text(this.cachedToggleText);
  }

  getTypeSelectorToggleText() {
    return this.typeSelector.getToggleText();
  }

  getFilename() {
    return this.$filenameInput.val();
  }

  setFilename(name) {
    this.$filenameInput.val(name).trigger('change');
  }

  getSelected() {
    return this.templateSelectors.find(selector => selector.selected);
  }
}
