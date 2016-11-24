/* eslint-disable class-methods-use-this */
(() => {
  window.gl = window.gl || {};

  class Members {
    constructor() {
      this.addListeners();
      this.initGLDropdown();
    }

    addListeners() {
      const ldapPermissionsChangeBtns = document.querySelectorAll('.js-ldap-permissions');
      const ldapOverrideBtns = document.querySelectorAll('.js-ldap-override');

      ldapPermissionsChangeBtns.forEach((btn) => {
        btn.addEventListener('click', this.showLDAPPermissionsWarning.bind(this));
      });

      ldapOverrideBtns.forEach((btn) => {
        btn.addEventListener('click', this.toggleMemberAccessToggle.bind(this));
      });

      $('.project_member, .group_member').off('ajax:success').on('ajax:success', this.removeRow);
      $('.js-member-update-control').off('change').on('change', this.formSubmit);
      $('.js-edit-member-form').off('ajax:success').on('ajax:success', this.formSuccess);
      gl.utils.disableButtonIfEmptyField('#user_ids', 'input[name=commit]', 'change');
    }

    initGLDropdown() {
      $('.js-member-permissions-dropdown').each((i, btn) => {
        const $btn = $(btn);

        $btn.glDropdown({
          selectable: true,
          isSelectable(selected, $el) {
            const $link = $($el);

            return $link.data('revert');
          },
          fieldName: $btn.data('field-name'),
          id(selected, $el) {
            return $el.data('id');
          },
          toggleLabel(selected, $el) {
            if ($el.data('revert')) {
              return $btn.text();
            }

            return $el.text();
          },
          clicked: (selected, $el) => {
            const $link = $($el);

            if ($link.data('revert')) {
              const memberListItem = this.getMemberListItem($link.get(0));
              const toggle = memberListItem.querySelectorAll('.dropdown-menu-toggle')[0];

              toggle.disabled = true;
              this.overrideLdap(memberListItem, $link.data('endpoint'), false);
            } else {
              $btn.closest('form').trigger('submit.rails');
            }
          },
        });
      });
    }

    static removeRow(e) {
      const $target = $(e.target);

      if ($target.hasClass('btn-remove')) {
        $target.closest('.member')
          .fadeOut(function fadeOutMemberRow() {
            $(this).remove();
          });
      }
    }

    formSubmit() {
      $(this).closest('form').trigger('submit.rails').end()
        .disable();
    }

    formSuccess() {
      $(this).find('.js-member-update-control').enable();
    }

    showLDAPPermissionsWarning(e) {
      const btn = e.currentTarget;
      const memberListItem = this.getMemberListItem(btn);
      const ldapPermissionsElement = memberListItem.nextElementSibling;

      if (ldapPermissionsElement.style.display === 'none') {
        ldapPermissionsElement.style.display = 'block';
      } else {
        ldapPermissionsElement.style.display = 'none';
      }
    }

    getMemberListItem(btn) {
      return document.getElementById(btn.dataset.id);
    }

    toggleMemberAccessToggle(e) {
      const btn = e.currentTarget;
      const memberListItem = this.getMemberListItem(btn);
      const toggle = memberListItem.querySelectorAll('.dropdown-menu-toggle')[0];

      this.showLDAPPermissionsWarning(e);
      toggle.removeAttribute('disabled');

      this.overrideLdap(memberListItem, btn.dataset.endpoint, true);
    }

    overrideLdap(memberListitem, endpoint, override) {
      if (override) {
        memberListitem.classList.add('is-overriden');
      } else {
        memberListitem.classList.remove('is-overriden');
      }

      return $.ajax({
        url: endpoint,
        type: 'PATCH',
        data: {
          group_member: {
            override,
          },
        },
      });
    }
  }

  gl.Members = Members;
})();
