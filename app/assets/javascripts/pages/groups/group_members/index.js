import Vue from 'vue';
import Members from 'ee_else_ce/members';
import memberExpirationDate from '~/member_expiration_date';
import UsersSelect from '~/users_select';
import groupsSelect from '~/groups_select';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';
import { initGroupMembersApp } from '~/groups/members';

function mountRemoveMemberModal() {
  const el = document.querySelector('.js-remove-member-modal');
  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createComponent) {
      return createComponent(RemoveMemberModal);
    },
  });
}

document.addEventListener('DOMContentLoaded', () => {
  groupsSelect();
  memberExpirationDate();
  memberExpirationDate('.js-access-expiration-date-groups');
  mountRemoveMemberModal();

  const SHARED_FIELDS = ['account', 'expires', 'maxRole', 'expiration', 'actions'];

  initGroupMembersApp(
    document.querySelector('.js-group-members-list'),
    SHARED_FIELDS.concat(['source', 'granted']),
  );
  initGroupMembersApp(
    document.querySelector('.js-group-linked-list'),
    SHARED_FIELDS.concat('granted'),
  );
  initGroupMembersApp(
    document.querySelector('.js-group-invited-members-list'),
    SHARED_FIELDS.concat('invited'),
  );
  initGroupMembersApp(
    document.querySelector('.js-group-access-requests-list'),
    SHARED_FIELDS.concat('requested'),
  );

  new Members(); // eslint-disable-line no-new
  new UsersSelect(); // eslint-disable-line no-new
});
