import Vue from 'vue';
import memberExpirationDate from '~/member_expiration_date';
import UsersSelect from '~/users_select';
import groupsSelect from '~/groups_select';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';
import { initGroupMembersApp } from '~/groups/members';
import initInviteMembersModal from '~/invite_members/init_invite_members_modal';
import initInviteMembersTrigger from '~/invite_members/init_invite_members_trigger';
import { memberRequestFormatter, groupLinkRequestFormatter } from '~/groups/members/utils';
import { s__ } from '~/locale';

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

initGroupMembersApp(document.querySelector('.js-group-members-list'), {
  tableFields: SHARED_FIELDS.concat(['source', 'granted']),
  tableAttrs: { tr: { 'data-qa-selector': 'member_row' } },
  tableSortableFields: ['account', 'granted', 'maxRole', 'lastSignIn'],
  requestFormatter: memberRequestFormatter,
  filteredSearchBar: {
    show: true,
    tokens: ['two_factor', 'with_inherited_permissions'],
    searchParam: 'search',
    placeholder: s__('Members|Filter members'),
    recentSearchesStorageKey: 'group_members',
  },
});
initGroupMembersApp(document.querySelector('.js-group-linked-list'), {
  tableFields: SHARED_FIELDS.concat('granted'),
  tableAttrs: {
    table: { 'data-qa-selector': 'groups_list' },
    tr: { 'data-qa-selector': 'group_row' },
  },
  requestFormatter: groupLinkRequestFormatter,
});
initGroupMembersApp(document.querySelector('.js-group-invited-members-list'), {
  tableFields: SHARED_FIELDS.concat('invited'),
  requestFormatter: memberRequestFormatter,
  filteredSearchBar: {
    show: true,
    tokens: [],
    searchParam: 'search_invited',
    placeholder: s__('Members|Search invited'),
    recentSearchesStorageKey: 'group_invited_members',
  },
});
initGroupMembersApp(document.querySelector('.js-group-access-requests-list'), {
  tableFields: SHARED_FIELDS.concat('requested'),
  requestFormatter: memberRequestFormatter,
});

groupsSelect();
memberExpirationDate();
memberExpirationDate('.js-access-expiration-date-groups');
mountRemoveMemberModal();
initInviteMembersModal();
initInviteMembersTrigger();

new UsersSelect(); // eslint-disable-line no-new
