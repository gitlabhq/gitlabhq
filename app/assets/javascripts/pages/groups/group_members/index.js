import Vue from 'vue';
import Members from 'ee_else_ce/members';
import memberExpirationDate from '~/member_expiration_date';
import UsersSelect from '~/users_select';
import groupsSelect from '~/groups_select';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';
import { initGroupMembersApp } from '~/groups/members';
import { memberRequestFormatter, groupLinkRequestFormatter } from '~/groups/members/utils';

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

const SHARED_FIELDS = ['account', 'expires', 'maxRole', 'expiration', 'actions'];
initGroupMembersApp(
  document.querySelector('.js-group-members-list'),
  SHARED_FIELDS.concat(['source', 'granted']),
  { tr: { 'data-qa-selector': 'member_row' } },
  memberRequestFormatter,
);
initGroupMembersApp(
  document.querySelector('.js-group-linked-list'),
  SHARED_FIELDS.concat('granted'),
  { table: { 'data-qa-selector': 'groups_list' }, tr: { 'data-qa-selector': 'group_row' } },
  groupLinkRequestFormatter,
);
initGroupMembersApp(
  document.querySelector('.js-group-invited-members-list'),
  SHARED_FIELDS.concat('invited'),
  {},
  memberRequestFormatter,
);
initGroupMembersApp(
  document.querySelector('.js-group-access-requests-list'),
  SHARED_FIELDS.concat('requested'),
  {},
  memberRequestFormatter,
);

groupsSelect();
memberExpirationDate();
memberExpirationDate('.js-access-expiration-date-groups');
mountRemoveMemberModal();

new Members(); // eslint-disable-line no-new
new UsersSelect(); // eslint-disable-line no-new
