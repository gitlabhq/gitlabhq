import { convertPermissionToBoolean } from '~/lib/utils/common_utils';

export default class AutoDevopsForm {
  constructor(formSelector) {
    this.ciCustomPath = document.querySelector('#js-general-pipeline-settings .js-ci-config-path');
    this.enableAutoDevOpsRadio = document.querySelector(`${formSelector} .js-enable-autodevops`);
    this.saveButton = document.querySelector(`${formSelector} .js-save-button`);
    this.saveButtonCopy = this.saveButton.cloneNode();
    this.saveButtonModal = document.querySelector(`${formSelector} .js-save-button-modal`);
    this.warningModal = document.querySelector(`${formSelector} #modal-disable-autodevops`);
    this.autoDevOpsEnabled = convertPermissionToBoolean(
      this.enableAutoDevOpsRadio.getAttribute('data-auto-devops-enabled'),
    );
    this.addSubmitButtonModal();
    this.updateRadioLegend();

    this.ciCustomPath.addEventListener('keyup', this.updateRadioLegend.bind(this));
  }

  addSubmitButtonModal() {
    this.saveButtonCopy.classList.remove('btn-save');
    this.saveButtonCopy.classList.add('btn-remove');
    this.saveButtonCopy.value = 'Disable Auto DevOps Pipelines';
    this.warningModal.querySelector('.modal-footer').appendChild(this.saveButtonCopy);
  }

  updateRadioLegend() {
    if (this.ciCustomPath.value !== '' && this.autoDevOpsEnabled) {
      this.saveButton.classList.add('hidden');
      this.saveButtonModal.classList.remove('hidden');
    } else {
      this.saveButton.classList.remove('hidden');
      this.saveButtonModal.classList.add('hidden');
    }
  }
}
