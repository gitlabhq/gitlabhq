/* eslint-disable */
((w) => {
  w.gl = w.gl || {};

  class Members {
    constructor() {
      this.addListeners();
    }

    addListeners() {
      const ldapPermissionsChangeBtns = document.querySelectorAll('.js-ldap-permissions');

      ldapPermissionsChangeBtns.forEach((btn) => {
        btn.addEventListener('click', this.showLDAPPermissionsWarning.bind(this));
      });

      $('.project_member, .group_member').off('ajax:success').on('ajax:success', this.removeRow);
      $('.js-member-update-control').off('change').on('change', this.formSubmit);
      $('.js-edit-member-form').off('ajax:success').on('ajax:success', this.formSuccess);
      gl.utils.disableButtonIfEmptyField('#user_ids', 'input[name=commit]', 'change');
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

    showLDAPPermissionsWarning (e) {
      const btn = e.currentTarget,
            ldapPermissionsElement = this.getLDAPPermissionsElement(btn);

      if (ldapPermissionsElement.style.display === 'none') {
        ldapPermissionsElement.style.display = 'block';
      } else {
        ldapPermissionsElement.style.display = 'none';
      }
    }

    getLDAPPermissionsElement (btn) {
      return document.getElementById(btn.dataset.id).nextElementSibling;
    }
  }

  gl.Members = Members;
})(window);
