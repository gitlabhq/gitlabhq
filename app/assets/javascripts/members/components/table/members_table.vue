<script>
import { GlTable, GlBadge, GlPagination } from '@gitlab/ui';
import { mapState } from 'vuex';
import MembersTableCell from 'ee_else_ce/members/components/table/members_table_cell.vue';
import { canOverride, canRemove, canResend, canUpdate } from 'ee_else_ce/members/utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import initUserPopovers from '~/user_popovers';
import { FIELDS, ACTIVE_TAB_QUERY_PARAM_NAME } from '../../constants';
import RemoveGroupLinkModal from '../modals/remove_group_link_modal.vue';
import CreatedAt from './created_at.vue';
import ExpirationDatepicker from './expiration_datepicker.vue';
import ExpiresAt from './expires_at.vue';
import MemberActionButtons from './member_action_buttons.vue';
import MemberAvatar from './member_avatar.vue';
import MemberSource from './member_source.vue';
import RoleDropdown from './role_dropdown.vue';

export default {
  name: 'MembersTable',
  components: {
    GlTable,
    GlBadge,
    GlPagination,
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
  inject: ['namespace', 'currentUserId'],
  props: {
    tabQueryParamValue: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState({
      members(state) {
        return state[this.namespace].members;
      },
      tableFields(state) {
        return state[this.namespace].tableFields;
      },
      tableAttrs(state) {
        return state[this.namespace].tableAttrs;
      },
      pagination(state) {
        return state[this.namespace].pagination;
      },
    }),
    filteredFields() {
      return FIELDS.filter(
        (field) => this.tableFields.includes(field.key) && this.showField(field),
      ).map((field) => {
        const tdClassFunction = this[field.tdClassFunction];

        return {
          ...field,
          ...(tdClassFunction && { tdClass: tdClassFunction }),
        };
      });
    },
    userIsLoggedIn() {
      return this.currentUserId !== null;
    },
    showPagination() {
      const { paramName, currentPage, perPage, totalItems } = this.pagination;

      return paramName && currentPage && perPage && totalItems;
    },
  },
  mounted() {
    initUserPopovers(this.$el.querySelectorAll('.js-user-link'));
  },
  methods: {
    hasActionButtons(member) {
      return (
        canRemove(member) ||
        canResend(member) ||
        canUpdate(member, this.currentUserId) ||
        canOverride(member)
      );
    },
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

      return this.members.some((member) => this.hasActionButtons(member));
    },
    tdClassActions(value, key, member) {
      if (this.hasActionButtons(member)) {
        return 'col-actions';
      }

      return ['col-actions', 'gl-display-none!', 'gl-lg-display-table-cell!'];
    },
    tbodyTrAttr(member) {
      return {
        ...this.tableAttrs.tr,
        ...(member?.id && { 'data-testid': `members-table-row-${member.id}` }),
      };
    },
    paginationLinkGenerator(page) {
      const { params = {}, paramName } = this.pagination;

      return mergeUrlParams(
        {
          ...params,
          [ACTIVE_TAB_QUERY_PARAM_NAME]:
            this.tabQueryParamValue !== '' ? this.tabQueryParamValue : null,
          [paramName]: page,
        },
        window.location.href,
      );
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
      :tbody-tr-attr="tbodyTrAttr"
    >
      <template #head()="{ label }">
        {{ label }}
      </template>
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
    <gl-pagination
      v-if="showPagination"
      :value="pagination.currentPage"
      :per-page="pagination.perPage"
      :total-items="pagination.totalItems"
      :link-gen="paginationLinkGenerator"
      :prev-text="__('Prev')"
      :next-text="__('Next')"
      :label-next-page="__('Go to next page')"
      :label-prev-page="__('Go to previous page')"
      align="center"
    />
    <remove-group-link-modal />
    <ldap-override-confirmation-modal />
  </div>
</template>
