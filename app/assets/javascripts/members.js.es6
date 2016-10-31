/* eslint-disable */
((w) => {
  w.gl = w.gl || {};

  class Members {
    constructor() {
      this.addListeners();
    }

    addListeners() {
      $('.project_member, .group_member').off('ajax:success').on('ajax:success', this.removeRow);
      $('.js-member-update-control').off('change').on('change', this.formSubmit);
      $('.js-edit-member-form').off('ajax:success').on('ajax:success', this.formSuccess);
      disableButtonIfEmptyField('#user_ids', 'input[name=commit]', 'change');
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
      $(this).closest('form').trigger("submit.rails").end().disable();
    }

    formSuccess() {
      $(this).find('.js-member-update-control').enable();
    }
  }

  gl.Members = Members;
})(window);
