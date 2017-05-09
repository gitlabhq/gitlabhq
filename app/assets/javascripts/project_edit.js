export default class ProjectEdit {
  constructor() {
    this.transferForm = $('.js-project-transfer-form');
    this.selectNamespace = $('.js-project-transfer-form').find('.select2');

    this.selectNamespaceChangedWrapper = this.selectNamespaceChanged.bind(this);
    this.selectNamespace.on('change', this.selectNamespaceChangedWrapper);
    this.selectNamespaceChanged();
  }

  selectNamespaceChanged() {
    const selectedNamespaceValue = this.selectNamespace.val();

    this.transferForm.find(':submit').prop('disabled', !selectedNamespaceValue);
  }
}
