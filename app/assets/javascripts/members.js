import $ from 'jquery';
import Flash from './flash';
import { __ } from './locale';
import axios from './lib/utils/axios_utils';

export default class Members {
  constructor() {
    this.addListeners();
    this.initGLDropdown();
  }

  addListeners() {
    $('.js-ldap-permissions').off('click').on('click', this.showLDAPPermissionsWarning.bind(this));
    $('.js-ldap-override').off('click').on('click', this.toggleMemberAccessToggle.bind(this));
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
          if ($el.data('revert')) {
            return false;
          }

          return !$el.hasClass('is-active');
        },
        fieldName: $btn.data('fieldName'),
        id(selected, $el) {
          return $el.data('id');
        },
        toggleLabel(selected, $el) {
          if ($el.data('revert')) {
            return $btn.text();
          }

          return $el.text();
        },
        clicked: (options) => {
          const $link = options.$el;

          if (!$link.data('revert')) {
            this.formSubmit(null, $link);
          } else {
            const { $memberListItem, $toggle, $dateInput } = this.getMemberListItems($link);

            $toggle.disable();
            $dateInput.disable();

            this.overrideLdap($memberListItem, $link.data('endpoint'), false)
              .catch(() => {
                $toggle.enable();
                $dateInput.enable();
              });
          }
        },
      });
    });
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

  showLDAPPermissionsWarning(e) {
    const $btn = $(e.currentTarget);
    const { $memberListItem } = this.getMemberListItems($btn);
    const $ldapPermissionsElement = $memberListItem.next();

    $ldapPermissionsElement.toggle();
  }
  // eslint-disable-next-line class-methods-use-this
  getMemberListItems($el) {
    const $memberListItem = $el.is('.member') ? $el : $(`#${$el.data('elId')}`);

    return {
      $memberListItem,
      $toggle: $memberListItem.find('.dropdown-menu-toggle'),
      $dateInput: $memberListItem.find('.js-access-expiration-date'),
    };
  }

  toggleMemberAccessToggle(e) {
    const $btn = $(e.currentTarget);
    const { $memberListItem, $toggle, $dateInput } = this.getMemberListItems($btn);

    $btn.disable();
    // eslint-disable-next-line promise/catch-or-return
    this.overrideLdap($memberListItem, $btn.data('endpoint'), true)
      .then(() => {
        this.showLDAPPermissionsWarning(e);

        $toggle.enable();
        $dateInput.enable();
      })
      .catch((xhr) => {
        $btn.enable();

        if (xhr.status === 403) {
          Flash(__('You do not have the correct permissions to override the settings from the LDAP group sync.'));
        } else {
          Flash(__('An error occurred while saving LDAP override status. Please try again.'));
        }
      });
  }
  // eslint-disable-next-line class-methods-use-this
  overrideLdap($memberListitem, endpoint, override) {
    return axios.patch(endpoint, {
      group_member: {
        override,
      },
    })
    .then(() => {
      $memberListitem.toggleClass('is-overriden', override);
    });
  }
}
