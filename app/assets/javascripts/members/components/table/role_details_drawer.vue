<script>
import { GlDrawer, GlBadge, GlSprintf, GlButton, GlIcon, GlAlert } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import MembersTableCell from 'ee_else_ce/members/components/table/members_table_cell.vue';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import { roleDropdownItems } from 'ee_else_ce/members/utils';
import {
  GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME,
  MEMBER_ACCESS_LEVEL_PROPERTY_NAME,
  MEMBERS_TAB_TYPES,
} from '~/members/constants';
import * as Sentry from '~/ci/runner/sentry_utils';
import MemberAvatar from './member_avatar.vue';
import RoleSelector from './role_selector.vue';

// The API to update members uses different property names for the access level, depending on if it's a user or a group.
// Users use 'access_level', groups use 'group_access'.
const ACCESS_LEVEL_PROPERTY_NAME = {
  [MEMBERS_TAB_TYPES.user]: MEMBER_ACCESS_LEVEL_PROPERTY_NAME,
  [MEMBERS_TAB_TYPES.group]: GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME,
};

export default {
  components: {
    MemberAvatar,
    MembersTableCell,
    GlDrawer,
    GlBadge,
    GlSprintf,
    GlButton,
    GlIcon,
    GlAlert,
    RoleSelector,
    GuestOverageConfirmation: () =>
      import('ee_component/members/components/table/guest_overage_confirmation.vue'),
  },
  inject: ['namespace', 'group'],
  props: {
    member: {
      type: Object,
      required: false,
      default: null,
    },
    memberPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedRole: null,
      isSavingRole: false,
      saveError: null,
    };
  },
  computed: {
    roles() {
      return roleDropdownItems(this.member);
    },
    initialRole() {
      const { memberRoleId = null, integerValue, stringValue } = this.member.accessLevel;
      const role = this.roles.flatten.find(
        (r) => r.memberRoleId === memberRoleId && r.accessLevel === integerValue,
      );
      // When the user doesn't have write access to the members list, the members data won't have custom roles. If the
      // member is assigned a custom role, there won't be an entry for it in the custom roles list, and the role name
      // won't be shown. To fix this, we'll return a fake role with just the role name and member role ID so that the
      // role name will be shown properly.
      return role || { text: stringValue, memberRoleId };
    },
  },
  watch: {
    'member.accessLevel': {
      immediate: true,
      handler() {
        if (this.member) {
          this.selectedRole = this.initialRole;
        }
      },
    },
    isSavingRole() {
      this.$emit('busy', this.isSavingRole);
    },
    selectedRole() {
      this.saveError = null;
    },
  },
  methods: {
    closeDrawer() {
      // Don't close the drawer if the role API call is still underway.
      if (!this.isSavingRole) {
        this.$emit('close');
      }
    },
    checkGuestOverage() {
      this.saveError = null;
      this.isSavingRole = true;
      const confirmOverageFn = this.$refs.guestOverageConfirmation.confirmOverage;
      // If guestOverageConfirmation is real instead of the CE dummy, check the guest overage. Otherwise, just update
      // the role.
      if (confirmOverageFn) {
        confirmOverageFn();
      } else {
        this.updateRole();
      }
    },
    async updateRole() {
      try {
        const url = this.memberPath.replace(':id', this.member.id);
        const accessLevelProp = ACCESS_LEVEL_PROPERTY_NAME[this.namespace];

        const { data } = await axios.put(url, {
          [accessLevelProp]: this.selectedRole.accessLevel,
          member_role_id: this.selectedRole.memberRoleId,
        });

        // EE has a flow where the role is not changed immediately, but goes through an approval process. In that case
        // we need to restore the role back to what the member had initially.
        if (data?.enqueued) {
          this.$toast.show(s__('Members|Role change request was sent to the administrator.'));
          this.resetRole();
        } else {
          this.$toast.show(s__('Members|Role was successfully updated.'));
          const { member } = this;
          // Update the access level on the member object so that the members table shows the new role.
          member.accessLevel = {
            stringValue: this.selectedRole.text,
            integerValue: this.selectedRole.accessLevel,
            description: this.selectedRole.description,
            memberRoleId: this.selectedRole.memberRoleId,
          };
          // Update the license usage info to show/hide the "Is using seat" badge.
          if (data?.using_license !== undefined) {
            member.usingLicense = data?.using_license;
          }
        }
      } catch (error) {
        this.saveError = s__('MemberRole|Could not update role.');
        Sentry.captureException(error);
      } finally {
        this.isSavingRole = false;
      }
    },
    resetRole() {
      this.selectedRole = this.initialRole;
      this.isSavingRole = false;
    },
    showCheckOverageError() {
      this.saveError = s__('MemberRole|Could not check guest overage.');
      this.isSavingRole = false;
    },
  },
  getContentWrapperHeight,
  helpPagePath,
  DRAWER_Z_INDEX,
  ACCESS_LEVEL_LABELS,
};
</script>

<template>
  <members-table-cell
    v-if="member"
    #default="{ memberType, isCurrentUser, permissions }"
    :member="member"
  >
    <gl-drawer
      :header-height="$options.getContentWrapperHeight()"
      header-sticky
      :z-index="$options.DRAWER_Z_INDEX"
      open
      @close="closeDrawer"
    >
      <template #title>
        <h4 class="gl-m-0">{{ s__('MemberRole|Role details') }}</h4>
      </template>

      <!-- Do not remove this div, it's needed because every top-level element in the drawer's body will get padding and
           a bottom border applied to it, and we don't want that to be applied to everything. -->
      <div>
        <h5 class="gl-mr-6">{{ __('Account') }}</h5>

        <member-avatar
          :member-type="memberType"
          :is-current-user="isCurrentUser"
          :member="member"
        />

        <hr />

        <dl>
          <dt class="gl-mb-3" data-testid="role-header">{{ s__('MemberRole|Role') }}</dt>
          <dd>
            <role-selector
              v-if="permissions.canUpdate"
              v-model="selectedRole"
              :roles="roles"
              :loading="isSavingRole"
              class="gl-mb-3"
            />
            <span v-else class="gl-mr-1" data-testid="role-text">{{ selectedRole.text }}</span>

            <gl-badge v-if="selectedRole.memberRoleId">
              {{ s__('MemberRole|Custom role') }}
            </gl-badge>
          </dd>

          <template v-if="selectedRole.description">
            <dt class="gl-mt-6 gl-mb-3" data-testid="description-header">
              {{ s__('MemberRole|Description') }}
            </dt>
            <dd data-testid="description-value">
              {{ selectedRole.description }}
            </dd>
          </template>

          <dt class="gl-mt-6 gl-mb-3" data-testid="permissions-header">
            {{ s__('MemberRole|Permissions') }}
          </dt>
          <dd class="gl-display-flex gl-mb-5">
            <span v-if="selectedRole.permissions" class="gl-mr-3" data-testid="base-role">
              <gl-sprintf :message="s__('MemberRole|Base role: %{role}')">
                <template #role>
                  {{ $options.ACCESS_LEVEL_LABELS[selectedRole.accessLevel] }}
                </template>
              </gl-sprintf>
            </span>
            <gl-button
              :href="$options.helpPagePath('user/permissions')"
              icon="external-link"
              variant="link"
              target="_blank"
              data-testid="view-permissions-button"
            >
              {{ s__('MemberRole|View permissions') }}
            </gl-button>
          </dd>

          <div
            v-for="permission in selectedRole.permissions"
            :key="permission.name"
            class="gl-display-flex"
            data-testid="permission"
          >
            <gl-icon name="check" class="gl-flex-shrink-0" />
            <div class="gl-mx-3">
              <span data-testid="permission-name">
                {{ permission.name }}
              </span>
              <p class="gl-mt-2 gl-text-secondary" data-testid="permission-description">
                {{ permission.description }}
              </p>
            </div>
          </div>
        </dl>
      </div>

      <template #footer>
        <div v-if="selectedRole !== initialRole">
          <gl-alert v-if="saveError" class="gl-mb-5" variant="danger" :dismissible="false">
            {{ saveError }}
          </gl-alert>
          <gl-button
            variant="confirm"
            :loading="isSavingRole"
            data-testid="save-button"
            @click="checkGuestOverage"
          >
            {{ s__('MemberRole|Update role') }}
          </gl-button>
          <gl-button
            class="gl-ml-2"
            :disabled="isSavingRole"
            data-testid="cancel-button"
            @click="resetRole"
          >
            {{ __('Cancel') }}
          </gl-button>
          <guest-overage-confirmation
            ref="guestOverageConfirmation"
            :group-path="group.path"
            :member="member"
            :role="selectedRole"
            @confirm="updateRole"
            @cancel="resetRole"
            @error="showCheckOverageError"
          />
        </div>
      </template>
    </gl-drawer>
  </members-table-cell>
</template>
