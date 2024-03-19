<script>
import { GlTable, GlBadge, GlPagination } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import MembersTableCell from 'ee_else_ce/members/components/table/members_table_cell.vue';
import {
  canDisableTwoFactor,
  canUnban,
  canOverride,
  canRemove,
  canRemoveBlockedByLastOwner,
  canResend,
  canUpdate,
} from 'ee_else_ce/members/utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import {
  FIELD_KEY_ACTIONS,
  FIELDS,
  ACTIVE_TAB_QUERY_PARAM_NAME,
  MEMBER_STATE_AWAITING,
  MEMBER_STATE_ACTIVE,
  USER_STATE_BLOCKED,
  BADGE_LABELS_AWAITING_SIGNUP,
  BADGE_LABELS_PENDING,
} from '../../constants';
import RemoveGroupLinkModal from '../modals/remove_group_link_modal.vue';
import RemoveMemberModal from '../modals/remove_member_modal.vue';
import CreatedAt from './created_at.vue';
import ExpirationDatepicker from './expiration_datepicker.vue';
import MemberActions from './member_actions.vue';
import MemberAvatar from './member_avatar.vue';
import MemberSource from './member_source.vue';
import MemberActivity from './member_activity.vue';
import MaxRole from './max_role.vue';

export default {
  name: 'MembersTable',
  components: {
    GlTable,
    GlBadge,
    GlPagination,
    MemberAvatar,
    CreatedAt,
    MembersTableCell,
    MemberSource,
    MemberActions,
    MaxRole,
    RemoveGroupLinkModal,
    RemoveMemberModal,
    ExpirationDatepicker,
    MemberActivity,
    DisableTwoFactorModal: () =>
      import('ee_component/members/components/modals/disable_two_factor_modal.vue'),
    LdapOverrideConfirmationModal: () =>
      import('ee_component/members/components/modals/ldap_override_confirmation_modal.vue'),
  },
  inject: ['namespace', 'currentUserId', 'canManageMembers'],
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
    filteredAndModifiedFields() {
      return FIELDS.filter(
        (field) => this.tableFields.includes(field.key) && this.showField(field),
      ).map((item) => this.modifyFieldDefinition(item));
    },
    userIsLoggedIn() {
      return this.currentUserId !== null;
    },
    showPagination() {
      const { paramName, currentPage, perPage, totalItems } = this.pagination;

      return paramName && currentPage && perPage && totalItems;
    },
  },
  methods: {
    hasActionButtons(member) {
      return (
        canRemove(member) ||
        canRemoveBlockedByLastOwner(member, this.canManageMembers) ||
        canResend(member) ||
        canUpdate(member, this.currentUserId) ||
        canOverride(member) ||
        canUnban(member) ||
        canDisableTwoFactor(member)
      );
    },
    showField(field) {
      switch (field.key) {
        case FIELD_KEY_ACTIONS:
          if (!this.userIsLoggedIn) {
            return false;
          }

          return this.members.some((member) => this.hasActionButtons(member));
        default:
          return true;
      }
    },
    modifyFieldDefinition(field) {
      switch (field.key) {
        case FIELD_KEY_ACTIONS:
          return {
            ...field,
            tdClass: this.actionsFieldTdClass,
          };
        default:
          return field;
      }
    },
    actionsFieldTdClass(value, key, member) {
      if (this.hasActionButtons(member)) {
        return ['col-actions', 'gl-vertical-align-middle!'];
      }

      return [
        'col-actions',
        'gl-display-none!',
        'gl-lg-display-table-cell!',
        'gl-vertical-align-middle!',
      ];
    },
    tbodyTrAttr(member) {
      return {
        ...this.tableAttrs.tr,
        ...(member?.id && {
          'data-testid': `members-table-row-${member.id}`,
        }),
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
    /**
     * Returns whether it's a new or existing user
     *
     * If memberInviteMetadata doesn't exist, it means we're adding an existing user
     * to the Group/Project, so `isNewUser` should be false.
     * If memberInviteMetadata exists but `userState` has content,
     * the user has registered but is awaiting root approval
     *
     * @param {object} memberInviteMetadata - MemberEntity.invite
     * @see {@link ~/app/serializers/member_entity.rb}
     * @returns {boolean}
     */
    isNewUser(memberInviteMetadata, memberState) {
      return (
        memberInviteMetadata &&
        !memberInviteMetadata.userState &&
        memberState !== MEMBER_STATE_ACTIVE
      );
    },
    /**
     * Returns whether the user is blocked awaiting root approval
     *
     * This checks User.state exposed via MemberEntity
     *
     * @param {object} memberInviteMetadata - MemberEntity.invite
     * @see {@link ~/app/serializers/member_entity.rb}
     * @returns {boolean}
     */
    isUserBlocked(memberInviteMetadata) {
      return memberInviteMetadata?.userState === USER_STATE_BLOCKED;
    },
    /**
     * Returns whether the member is awaiting state
     *
     * This checks Member.state exposed via MemberEntity
     *
     * @param {Number} memberState - Member.state exposed via MemberEntity.state
     * @see {@link ~/ee/app/models/ee/member.rb}
     * @see {@link ~/app/serializers/member_entity.rb}
     * @returns {boolean}
     */
    isMemberAwaiting(memberState) {
      return memberState === MEMBER_STATE_AWAITING;
    },
    isUserAwaiting(memberInviteMetadata, memberState) {
      return this.isUserBlocked(memberInviteMetadata) || this.isMemberAwaiting(memberState);
    },
    shouldAddPendingBadge(memberInviteMetadata, memberState) {
      return (
        this.isUserAwaiting(memberInviteMetadata, memberState) &&
        !this.isNewUser(memberInviteMetadata)
      );
    },
    /**
     * Returns the string to be used in the invite badge
     *
     * @param {object} memberInviteMetadata - MemberEntity.invite
     * @see {@link ~/app/serializers/member_entity.rb}
     * @param {Number} memberState - Member.state exposed via MemberEntity.state
     * @see {@link ~/ee/app/models/ee/member.rb}
     * @returns {string}
     */
    inviteBadge(memberInviteMetadata, memberState) {
      if (this.isNewUser(memberInviteMetadata, memberState)) {
        return BADGE_LABELS_AWAITING_SIGNUP;
      }

      if (this.shouldAddPendingBadge(memberInviteMetadata, memberState)) {
        return BADGE_LABELS_PENDING;
      }

      return '';
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
      stacked="lg"
      :fields="filteredAndModifiedFields"
      :items="members"
      primary-key="id"
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
          <member-source
            :is-direct-member="isDirectMember"
            :member-source="member.source"
            :created-by="member.createdBy"
            :is-shared-with-group-private="member.isSharedWithGroupPrivate"
          />
        </members-table-cell>
      </template>

      <template #cell(granted)="{ item: { createdAt, createdBy } }">
        <created-at :date="createdAt" :created-by="createdBy" />
      </template>

      <template #cell(invited)="{ item: { createdAt, createdBy, invite, state } }">
        <div
          class="gl-display-flex gl-align-items-center gl-justify-content-end gl-lg-justify-content-start gl-flex-wrap gl-gap-3"
        >
          <created-at :date="createdAt" :created-by="createdBy" />
          <gl-badge v-if="inviteBadge(invite, state)" data-testid="invited-badge"
            >{{ inviteBadge(invite, state) }}
          </gl-badge>
        </div>
      </template>

      <template #cell(requested)="{ item: { createdAt } }">
        <created-at :date="createdAt" />
      </template>

      <template #cell(maxRole)="{ item: member }">
        <members-table-cell #default="{ permissions }" :member="member">
          <max-role :permissions="permissions" :member="member" />
        </members-table-cell>
      </template>

      <template #cell(expiration)="{ item: member }">
        <members-table-cell #default="{ permissions }" :member="member">
          <expiration-datepicker :permissions="permissions" :member="member" />
        </members-table-cell>
      </template>

      <template #cell(activity)="{ item: member }">
        <member-activity :member="member" />
      </template>

      <template #cell(actions)="{ item: member }">
        <members-table-cell #default="{ memberType, isCurrentUser, permissions }" :member="member">
          <member-actions
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
    <disable-two-factor-modal />
    <remove-group-link-modal />
    <remove-member-modal />
    <ldap-override-confirmation-modal />
  </div>
</template>
