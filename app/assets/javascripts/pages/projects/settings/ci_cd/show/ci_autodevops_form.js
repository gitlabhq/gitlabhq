import { s__, sprintf } from '~/locale';
import { convertPermissionToBoolean } from '~/lib/utils/common_utils';

export default class AutoDevopsForm {
  constructor(formSelector) {
    this.ciCustomPath = document.querySelector(`${formSelector} .js-ci-config-path`);
    this.enableAutoDevOpsRadio = document.querySelector(`${formSelector} .js-enable-autodevops`);
    this.enableAutoDevOpsRadioDesc = this.enableAutoDevOpsRadio.querySelector('span.descr');
    this.saveButton = document.querySelector(`${formSelector} .js-save-button`);
    this.saveButtonCopy = this.saveButton.cloneNode();
    this.saveButtonModal = document.querySelector(`${formSelector} .js-save-button-modal`);
    this.warningModal = document.querySelector(`${formSelector} #modal-disable-autodevops`);
    this.autoDevOpsEnabled = convertPermissionToBoolean(
      this.enableAutoDevOpsRadio.getAttribute('data-auto-devops-enabled'),
    );
    this.setUpMessages();
    this.addSubmitButtonModal();

    this.ciCustomPath.addEventListener('keyup', this.updateRadioLegend.bind(this));
  }

  addSubmitButtonModal() {
    this.saveButtonCopy.classList.remove('btn-save');
    this.saveButtonCopy.classList.add('btn-remove');
    this.saveButtonCopy.value = 'Disable Auto DevOps Pipelines';
    this.warningModal.querySelector('.modal-footer').appendChild(this.saveButtonCopy);
  }

  setUpMessages() {
    this.DevOpsRadioPrevDesc = this.enableAutoDevOpsRadioDesc.innerHTML;
    // TODO: Need the actual link to the MR
    this.devOpsMessage = sprintf(
      s__(`CICD|The Auto DevOps configuration is not in use 
      because a custom CI path is set. %{removeLink}`),
      { removeLink: '<a>Remove custom CI file</a>' },
      false,
    );
  }

  updateRadioLegend() {
    if (this.ciCustomPath.value !== '' && this.autoDevOpsEnabled) {
      this.enableAutoDevOpsRadioDesc.innerHTML = this.devOpsMessage;
      this.saveButton.classList.add('hidden');
      this.saveButtonModal.classList.remove('hidden');
    } else {
      this.enableAutoDevOpsRadioDesc.innerHTML = this.DevOpsRadioPrevDesc;
      this.saveButton.classList.remove('hidden');
      this.saveButtonModal.classList.add('hidden');
    }
  }
}
