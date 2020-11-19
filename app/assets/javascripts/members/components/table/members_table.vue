<script>
import { mapState } from 'vuex';
import { GlTable, GlBadge } from '@gitlab/ui';
import MembersTableCell from 'ee_else_ce/members/components/table/members_table_cell.vue';
import { canOverride, canRemove, canResend, canUpdate } from 'ee_else_ce/members/utils';
import { FIELDS } from '../../constants';
import initUserPopovers from '~/user_popovers';
import MemberAvatar from './member_avatar.vue';
import MemberSource from './member_source.vue';
import CreatedAt from './created_at.vue';
import ExpiresAt from './expires_at.vue';
import MemberActionButtons from './member_action_buttons.vue';
import RoleDropdown from './role_dropdown.vue';
import RemoveGroupLinkModal from '../modals/remove_group_link_modal.vue';
import ExpirationDatepicker from './expiration_datepicker.vue';

export default {
  name: 'MembersTable',
  components: {
    GlTable,
    GlBadge,
    MemberAvatar,
    CreatedAt,
    ExpiresAt,
    MembersTableCell,
    MemberSource,
    MemberActionButtons,
    RoleDropdown,
    RemoveGroupLinkModal,
    ExpirationDatepicker,
    LdapOverrideConfirmationModal: () =>
      import('ee_component/members/components/ldap/ldap_override_confirmation_modal.vue'),
  },
  computed: {
    ...mapState(['members', 'tableFields', 'tableAttrs', 'currentUserId', 'sourceId']),
    filteredFields() {
      return FIELDS.filter(field => this.tableFields.includes(field.key) && this.showField(field));
    },
    userIsLoggedIn() {
      return this.currentUserId !== null;
    },
  },
  mounted() {
    initUserPopovers(this.$el.querySelectorAll('.js-user-link'));
  },
  methods: {
    showField(field) {
      if (!Object.prototype.hasOwnProperty.call(field, 'showFunction')) {
        return true;
      }

      return this[field.showFunction]();
    },
    showActionsField() {
      if (!this.userIsLoggedIn) {
        return false;
      }

      return this.members.some(member => {
        return (
          canRemove(member, this.sourceId) ||
          canResend(member) ||
          canUpdate(member, this.currentUserId, this.sourceId) ||
          canOverride(member)
        );
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-table
      v-bind="tableAttrs.table"
      class="members-table"
      data-testid="members-table"
      head-variant="white"
      stacked="lg"
      :fields="filteredFields"
      :items="members"
      primary-key="id"
      thead-class="border-bottom"
      :empty-text="__('No members found')"
      show-empty
      :tbody-tr-attr="tableAttrs.tr"
    >
      <template #cell(account)="{ item: member }">
        <members-table-cell #default="{ memberType, isCurrentUser }" :member="member">
          <member-avatar
            :member-type="memberType"
            :is-current-user="isCurrentUser"
            :member="member"
          />
        </members-table-cell>
      </template>

      <template #cell(source)="{ item: member }">
        <members-table-cell #default="{ isDirectMember }" :member="member">
          <member-source :is-direct-member="isDirectMember" :member-source="member.source" />
        </members-table-cell>
      </template>

      <template #cell(granted)="{ item: { createdAt, createdBy } }">
        <created-at :date="createdAt" :created-by="createdBy" />
      </template>

      <template #cell(invited)="{ item: { createdAt, createdBy } }">
        <created-at :date="createdAt" :created-by="createdBy" />
      </template>

      <template #cell(requested)="{ item: { createdAt } }">
        <created-at :date="createdAt" />
      </template>

      <template #cell(expires)="{ item: { expiresAt } }">
        <expires-at :date="expiresAt" />
      </template>

      <template #cell(maxRole)="{ item: member }">
        <members-table-cell #default="{ permissions }" :member="member">
          <role-dropdown v-if="permissions.canUpdate" :permissions="permissions" :member="member" />
          <gl-badge v-else>{{ member.accessLevel.stringValue }}</gl-badge>
        </members-table-cell>
      </template>

      <template #cell(expiration)="{ item: member }">
        <members-table-cell #default="{ permissions }" :member="member">
          <expiration-datepicker :permissions="permissions" :member="member" />
        </members-table-cell>
      </template>

      <template #cell(actions)="{ item: member }">
        <members-table-cell #default="{ memberType, isCurrentUser, permissions }" :member="member">
          <member-action-buttons
            :member-type="memberType"
            :is-current-user="isCurrentUser"
            :permissions="permissions"
            :member="member"
          />
        </members-table-cell>
      </template>

      <template #head(actions)="{ label }">
        <span data-testid="col-actions" class="gl-sr-only">{{ label }}</span>
      </template>
    </gl-table>
    <remove-group-link-modal />
    <ldap-override-confirmation-modal />
  </div>
</template>
