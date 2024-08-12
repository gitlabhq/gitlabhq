import $ from 'jquery';

import Api from '~/api';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import mountFilepathForm from '~/blob/filepath_form';

export default class FilepathFormMediator {
  constructor({ editor, currentAction, projectId }) {
    this.editor = editor;
    this.currentAction = currentAction;
    this.projectId = projectId;

    this.initFilepathForm();
    this.initDomElements();
    this.cacheFileContents();
  }

  initFilepathForm() {
    const handleTemplateSelect = ({ template, type, clearSelectedTemplate, stopLoading }) => {
      this.selectTemplateFile(template, type, clearSelectedTemplate, stopLoading);
    };
    mountFilepathForm({ action: this.currentAction, onTemplateSelected: handleTemplateSelect });
  }

  initDomElements() {
    const $fileEditor = $('.file-editor');

    this.$filenameInput = $fileEditor.find('.js-file-path-name-input');
  }

  // eslint-disable-next-line max-params
  selectTemplateFile(template, type, clearSelectedTemplate, stopLoading) {
    const self = this;

    this.fetchFileTemplate(type.type, template.key, template)
      .then((file) => {
        this.setEditorContent(file);
        this.setFilename(type.name);

        toast(sprintf(__('%{templateType} template applied'), { templateType: template.key }), {
          action: {
            text: __('Undo'),
            onClick: (e, toastObj) => {
              clearSelectedTemplate();
              self.restoreFromCache();
              toastObj.hide();
            },
          },
        });
      })
      .catch((err) =>
        createAlert({
          message: sprintf(__('An error occurred while fetching the template: %{err}'), { err }),
        }),
      )
      .finally(() => stopLoading());
  }

  fetchFileTemplate(type, query, data = {}) {
    return new Promise((resolve) => {
      const resolveFile = (file) => resolve(file);

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

  cacheFileContents() {
    this.cachedContent = this.editor.getValue();
  }

  restoreFromCache() {
    this.setEditorContent(this.cachedContent);
  }

  getFilename() {
    return this.$filenameInput.val();
  }

  setFilename(name) {
    const input = this.$filenameInput.get(0);
    if (name !== undefined && input.value !== name) {
      input.value = name;
      input.dispatchEvent(new Event('input'));
    }
  }
}
