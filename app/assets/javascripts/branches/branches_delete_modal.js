import $ from 'jquery';

const MODAL_SELECTOR = '#modal-delete-branch';

class DeleteModal {
  constructor() {
    this.$modal = $(MODAL_SELECTOR);
    this.$toggleBtns = $(`[data-target="${MODAL_SELECTOR}"]`);
    this.$branchName = $('.js-branch-name', this.$modal);
    this.$confirmInput = $('.js-delete-branch-input', this.$modal);
    this.$deleteBtn = $('.js-delete-branch', this.$modal);
    this.$notMerged = $('.js-not-merged', this.$modal);
    this.bindEvents();
  }

  bindEvents() {
    this.$toggleBtns.on('click', this.setModalData.bind(this));
    this.$confirmInput.on('input', this.setDeleteDisabled.bind(this));
  }

  setModalData(e) {
    const branchData = e.currentTarget.dataset;
    this.branchName = branchData.branchName || '';
    this.deletePath = branchData.deletePath || '';
    this.isMerged = !!branchData.isMerged;
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
    this.$notMerged.toggleClass('hidden', this.isMerged);
  }
}

export default DeleteModal;
