const MODAL_SELECTOR = '#modal-delete-branch';

class DeleteModal {
  constructor() {
    this.$modal = $(MODAL_SELECTOR);
    this.$toggleBtns = $(`[data-target="${MODAL_SELECTOR}"]`);
    this.$branchName = $('.js-branch-name', this.$modal);
    this.$confirmInput = $('.js-delete-branch-input', this.$modal);
    this.$deleteBtn = $('.js-delete-branch', this.$modal);
    this.bindEvents();
  }

  bindEvents() {
    this.$toggleBtns.on('click', this.setModalData.bind(this));
    this.$confirmInput.on('input', this.setDeleteDisabled.bind(this));
  }

  setModalData(e) {
    this.branchName = e.currentTarget.dataset.branchName || '';
    this.deletePath = e.currentTarget.dataset.deletePath || '';
    this.updateModal();
  }

  setDeleteDisabled(e) {
    this.$deleteBtn.attr('disabled', e.currentTarget.value !== this.branchName);
  }

  updateModal() {
    this.$branchName.text(this.branchName);
    this.$confirmInput.val('');
    this.$deleteBtn.attr('href', this.deletePath);
    this.$deleteBtn.attr('disabled', true);
  }
}

export default DeleteModal;
