/* eslint-disable class-methods-use-this */
(() => {
  window.gl = window.gl || {};

  class Members {
    constructor() {
      this.addListeners();
      this.initGLDropdown();
    }

    addListeners() {
      $('.project_member, .group_member').off('ajax:success').on('ajax:success', this.removeRow);
      $('.js-member-update-control').off('change').on('change', this.formSubmit.bind(this));
      $('.js-edit-member-form').off('ajax:success').on('ajax:success', this.formSuccess.bind(this));
      gl.utils.disableButtonIfEmptyField('#user_ids', 'input[name=commit]', 'change');
    }

    initGLDropdown() {
      $('.js-member-permissions-dropdown').each((i, btn) => {
        const $btn = $(btn);

        $btn.glDropdown({
          selectable: true,
          isSelectable(selected, $el) {
            return !$el.hasClass('is-active');
          },
          fieldName: $btn.data('field-name'),
          id(selected, $el) {
            return $el.data('id');
          },
          toggleLabel(selected, $el) {
            return $el.text();
          },
<<<<<<< HEAD
          clicked: (selected, $link) => {
            this.formSubmit(null, $link);
=======
          clicked: (options) => {
            const $link = options.$el;

            if (!$link.data('revert')) {
              this.formSubmit(null, $link);
            } else {
              const { $memberListItem, $toggle, $dateInput } = this.getMemberListItems($link);

              $toggle.disable();
              $dateInput.disable();

              this.overrideLdap($memberListItem, $link.data('endpoint'), false).fail(() => {
                $toggle.enable();
                $dateInput.enable();
              });
            }
>>>>>>> b0a2435... Merge branch 'multiple_assignees_review_upstream' into ee_master
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

    formSubmit(e, $el = null) {
      const $this = e ? $(e.currentTarget) : $el;
      const { $toggle, $dateInput } = this.getMemberListItems($this);

      $this.closest('form').trigger('submit.rails');

      $toggle.disable();
      $dateInput.disable();
    }

    formSuccess(e) {
      const { $toggle, $dateInput } = this.getMemberListItems($(e.currentTarget).closest('.member'));

      $toggle.enable();
      $dateInput.enable();
    }

    getMemberListItems($el) {
      const $memberListItem = $el.is('.member') ? $el : $(`#${$el.data('el-id')}`);

      return {
        $memberListItem,
        $toggle: $memberListItem.find('.dropdown-menu-toggle'),
        $dateInput: $memberListItem.find('.js-access-expiration-date'),
      };
    }
  }

  gl.Members = Members;
})();
