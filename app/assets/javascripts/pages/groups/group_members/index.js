import Vue from 'vue';
import Members from 'ee_else_ce/members';
import memberExpirationDate from '~/member_expiration_date';
import UsersSelect from '~/users_select';
import groupsSelect from '~/groups_select';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';
import { initGroupMembersApp } from '~/groups/members';
import { memberRequestFormatter, groupLinkRequestFormatter } from '~/groups/members/utils';
import { __ } from '~/locale';

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
    placeholder: __('Members|Filter members'),
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
    placeholder: __('Members|Search invited'),
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

new Members(); // eslint-disable-line no-new
new UsersSelect(); // eslint-disable-line no-new
