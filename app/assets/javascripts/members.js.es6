((w) => {
  w.gl = w.gl || {};

  class Members {
    constructor() {
      this.removeListeners();
      this.addListeners();
    }

    removeListeners() {
      $('.project_member, .group_member').off('ajax:success');
      $('.js-member-update-control').off('change');
      $('.js-edit-member-form').off('ajax:success');
    }

    addListeners() {
      $('.project_member, .group_member').on('ajax:success', this.removeRow);
      $('.js-member-update-control').on('change', this.formSubmit);
      $('.js-edit-member-form').on('ajax:success', this.formSuccess);
    }

    removeRow(e) {
      const $target = $(e.target);

      if ($target.hasClass('btn-remove')) {
        $target.closest('.member')
          .fadeOut(function () {
            $(this).remove();
          });
      }
    }

    formSubmit() {
      const $this = $(this);

      $this.closest('form')
        .trigger("submit.rails");

      $this.disable();
    }

    formSuccess() {
      $(this).find('.js-member-update-control').enable();
    }
  }

  gl.Members = Members;
})(window);
