import $ from 'jquery';
import Api from '~/api';

import Flash from '../flash';
import FileTemplateTypeSelector from './template_selectors/type_selector';
import BlobCiYamlSelector from './template_selectors/ci_yaml_selector';
import DockerfileSelector from './template_selectors/dockerfile_selector';
import GitignoreSelector from './template_selectors/gitignore_selector';
import LicenseSelector from './template_selectors/license_selector';
import toast from '~/vue_shared/plugins/global_toast';
import { __ } from '~/locale';

export default class FileTemplateMediator {
  constructor({ editor, currentAction, projectId }) {
    this.editor = editor;
    this.currentAction = currentAction;
    this.projectId = projectId;

    this.initTemplateSelectors();
    this.initTemplateTypeSelector();
    this.initDomElements();
    this.initDropdowns();
    this.initPageEvents();
    this.cacheFileContents();
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
      dropdownData: this.templateSelectors.map(templateSelector => {
        const cfg = templateSelector.config;

        return {
          name: cfg.name,
          key: cfg.key,
          id: cfg.key,
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
    this.$templateTypes = this.$templateSelectors.find('.template-type-selector');
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
    this.$navLinks.on('click', 'a', e => {
      const urlPieces = e.target.href.split('#');
      const hash = urlPieces[1];
      if (hash === 'preview') {
        this.hideTemplateSelectorMenu();
      } else if (hash === 'editor' && !this.typeSelector.isHidden()) {
        this.showTemplateSelectorMenu();
      }
    });
  }

  selectTemplateType(item, e) {
    if (e) {
      e.preventDefault();
    }

    this.templateSelectors.forEach(selector => {
      if (selector.config.key === item.key) {
        selector.show();
      } else {
        selector.hide();
      }
    });

    if (this.editor.getValue() !== '') {
      this.setTypeSelectorToggleText(item.name);
    }

    this.cacheToggleText();
  }

  selectTemplateTypeOptions(options) {
    this.selectTemplateType(options.selectedObj, options.e);
  }

  selectTemplateFile(selector, query, data) {
    const self = this;
    const { name } = selector.config;

    selector.renderLoading();

    this.fetchFileTemplate(selector.config.type, query, data)
      .then(file => {
        this.setEditorContent(file);
        this.setFilename(name);
        selector.renderLoaded();
        this.typeSelector.setToggleText(name);
        toast(__(`${query} template applied`), {
          action: {
            text: __('Undo'),
            onClick: (e, toastObj) => {
              self.restoreFromCache();
              toastObj.goAway(0);
            },
          },
        });
      })
      .catch(err => new Flash(`An error occurred while fetching the template: ${err}`));
  }

  displayMatchedTemplateSelector() {
    const currentInput = this.getFilename();
    this.templateSelectors.forEach(selector => {
      const match = selector.config.pattern.test(currentInput);

      if (match) {
        this.typeSelector.show();
        this.selectTemplateType(selector.config);
        this.showTemplateSelectorMenu();
      }
    });
  }

  fetchFileTemplate(type, query, data = {}) {
    return new Promise(resolve => {
      const resolveFile = file => resolve(file);

      Api.projectTemplate(this.projectId, type, query, data, resolveFile);
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
    this.setTypeSelectorToggleText(__('Select a template type'));
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

  setTypeSelectorToggleText(text) {
    this.typeSelector.setToggleText(text);
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
