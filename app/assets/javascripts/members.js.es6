/* eslint-disable class-methods-use-this */
(() => {
  window.gl = window.gl || {};

  class Members {
    constructor() {
      this.addListeners();
      this.initGLDropdown();
    }

    addListeners() {
      $('.js-ldap-permissions').off('click').on('click', this.showLDAPPermissionsWarning.bind(this));
      $('.js-ldap-override').off('click').on('click', this.toggleMemberAccessToggle.bind(this));
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

            if ($link.data('revert')) {
              return false;
            }

            return !$link.hasClass('is-active');
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
              const { $memberListItem, $toggle, $dateInput } = this.getMemberListItems($link);

              $toggle.attr('disabled', true);
              $dateInput.attr('disabled', true);
              this.overrideLdap($memberListItem, $link.data('endpoint'), false);
            } else {
              $btn.closest('form').trigger('submit.rails');
            }
          },
        });
      });
    }

    removeRow(e) {
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
      const $btn = $(e.currentTarget);
      const { $memberListItem } = this.getMemberListItems($btn);
      const $ldapPermissionsElement = $memberListItem.next();

      $ldapPermissionsElement.toggle();
    }

    getMemberListItems(btn) {
      const $memberListItem = $(`#${btn.data('id')}`);

      return {
        $memberListItem,
        $toggle: $memberListItem.find('.dropdown-menu-toggle'),
        $dateInput: $memberListItem.find('.js-access-expiration-date'),
      };
    }

    toggleMemberAccessToggle(e) {
      const $btn = $(e.currentTarget);
      const { $memberListItem, $toggle, $dateInput } = this.getMemberListItems($btn);

      this.showLDAPPermissionsWarning(e);
      $toggle.removeAttr('disabled');
      $dateInput.removeAttr('disabled');

      this.overrideLdap($memberListItem, $btn.data('endpoint'), true);
    }

    overrideLdap($memberListitem, endpoint, override) {
      $memberListitem.toggleClass('is-overriden', override);

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
