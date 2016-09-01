((w) => {
  w.gl = w.gl || {};

  class ProjectMembers {
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
      $('.js-member-update-control').on('change', function () {
        $(this).closest('form')
          .trigger("submit.rails");
        $(this).disable();
      });
      $('.js-edit-member-form').on('ajax:success', function () {
        $(this).find('.js-member-update-control').enable();
      });
    }

    removeRow(e) {
      const $target = $(e.target);

      if ($target.hasClass('btn-remove')) {
        console.log('a');
        $target.closest('.member').fadeOut();
      }
    }

    submitForm() {

    }
  }

  gl.ProjectMembers = ProjectMembers;
})(window);
