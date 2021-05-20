import Vue from 'vue';
import groupsSelect from '~/groups_select';
import initInviteGroupTrigger from '~/invite_members/init_invite_group_trigger';
import initInviteMembersForm from '~/invite_members/init_invite_members_form';
import initInviteMembersModal from '~/invite_members/init_invite_members_modal';
import initInviteMembersTrigger from '~/invite_members/init_invite_members_trigger';
import { s__ } from '~/locale';
import memberExpirationDate from '~/member_expiration_date';
import { initMembersApp } from '~/members';
import { MEMBER_TYPES } from '~/members/constants';
import { groupLinkRequestFormatter } from '~/members/utils';
import { projectMemberRequestFormatter } from '~/projects/members/utils';
import UsersSelect from '~/users_select';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';

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

groupsSelect();
memberExpirationDate();
memberExpirationDate('.js-access-expiration-date-groups');
mountRemoveMemberModal();
initInviteMembersModal();
initInviteMembersTrigger();
initInviteGroupTrigger();

// This is only used when `invite_members_group_modal` feature flag is disabled.
// This can be removed when `invite_members_group_modal` feature flag is removed.
initInviteMembersForm();

new UsersSelect(); // eslint-disable-line no-new

const SHARED_FIELDS = ['account', 'expires', 'maxRole', 'expiration', 'actions'];
initMembersApp(document.querySelector('.js-project-members-list-app'), {
  [MEMBER_TYPES.user]: {
    tableFields: SHARED_FIELDS.concat(['source', 'granted']),
    tableAttrs: { tr: { 'data-qa-selector': 'member_row' } },
    tableSortableFields: ['account', 'granted', 'maxRole', 'lastSignIn'],
    requestFormatter: projectMemberRequestFormatter,
    filteredSearchBar: {
      show: true,
      tokens: ['with_inherited_permissions'],
      searchParam: 'search',
      placeholder: s__('Members|Filter members'),
      recentSearchesStorageKey: 'project_members',
    },
  },
  [MEMBER_TYPES.group]: {
    tableFields: SHARED_FIELDS.concat('granted'),
    tableAttrs: {
      table: { 'data-qa-selector': 'groups_list' },
      tr: { 'data-qa-selector': 'group_row' },
    },
    requestFormatter: groupLinkRequestFormatter,
    filteredSearchBar: {
      show: true,
      tokens: [],
      searchParam: 'search_groups',
      placeholder: s__('Members|Search groups'),
      recentSearchesStorageKey: 'project_group_links',
    },
  },
  [MEMBER_TYPES.invite]: {
    tableFields: SHARED_FIELDS.concat('invited'),
    requestFormatter: projectMemberRequestFormatter,
  },
  [MEMBER_TYPES.accessRequest]: {
    tableFields: SHARED_FIELDS.concat('requested'),
    requestFormatter: projectMemberRequestFormatter,
  },
});
