((w) => {
  window.gl = window.gl || {};

  class ProjectMembers {
    constructor() {
      this.removeListeners();
      this.addListeners();
    }

    removeListeners() {
      $('.project_member').off('ajax:success');
      $('.js-member-update-control').off('change');
    }

    addListeners() {
      $('.project_member').on('ajax:success', this.removeRow);
      $('.js-member-update-control').on('change', function () {
        $(this).closest('form')
          .trigger("submit.rails");
      });
    }

    removeRow(e) {
      const $target = $(e.target);

      if ($target.hasClass('btn-remove')) {
        $target.fadeOut();
      }
    }

    submitForm() {

    }
  }

  gl.ProjectMembers = ProjectMembers;
})(window);
