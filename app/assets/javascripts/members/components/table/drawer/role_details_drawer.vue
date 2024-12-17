<script>
import { GlDrawer, GlSprintf, GlButton, GlIcon, GlAlert } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import MembersTableCell from 'ee_else_ce/members/components/table/members_table_cell.vue';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import {
  getRoleDropdownItems,
  getMemberRole,
} from 'ee_else_ce/members/components/table/drawer/utils';
import RoleUpdater from 'ee_else_ce/members/components/table/drawer/role_updater.vue';
import RoleSelector from '~/members/components/role_selector.vue';
import MemberAvatar from '../member_avatar.vue';

export default {
  components: {
    MemberAvatar,
    MembersTableCell,
    GlDrawer,
    GlSprintf,
    GlButton,
    GlIcon,
    GlAlert,
    RoleSelector,
    RoleUpdater,
    RoleBadges: () => import('ee_component/members/components/table/role_badges.vue'),
  },
  props: {
    member: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      selectedRole: null,
      isSavingRole: false,
      alert: null,
    };
  },
  computed: {
    roles() {
      return getRoleDropdownItems(this.member);
    },
    initialRole() {
      return getMemberRole(this.roles.flatten, this.member);
    },
    isRoleChanged() {
      return this.selectedRole !== this.initialRole;
    },
  },
  watch: {
    member: {
      immediate: true,
      handler() {
        if (this.member) {
          this.alert = null;
          this.selectedRole = this.initialRole;
        }
      },
    },
    isSavingRole() {
      this.$emit('busy', this.isSavingRole);
    },
  },
  methods: {
    closeDrawer() {
      // Don't let the drawer close if the role is still saving.
      if (!this.isSavingRole) {
        this.$emit('close');
        this.alert = null;
      }
    },
    setRole(role) {
      this.selectedRole = role;
      this.alert = null;
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
          <dd class="gl-flex gl-flex-wrap gl-items-baseline gl-gap-3">
            <role-selector
              v-if="permissions.canUpdate"
              :value="selectedRole"
              :roles="roles"
              :loading="isSavingRole"
              class="gl-w-full"
              @input="setRole"
            />
            <span v-else data-testid="role-text">{{ selectedRole.text }}</span>
            <role-badges :member="member" :role="selectedRole" />
          </dd>

          <dt class="gl-mb-3 gl-mt-6" data-testid="description-header">
            {{ s__('MemberRole|Description') }}
          </dt>
          <dd data-testid="description-value">
            <template v-if="member.accessLevel.description">{{
              member.accessLevel.description
            }}</template>
            <span v-else class="gl-text-subtle">{{ s__('MemberRole|No description') }}</span>
          </dd>

          <dt class="gl-mb-3 gl-mt-6" data-testid="permissions-header">
            {{ __('Permissions') }}
          </dt>
          <dd class="gl-mb-5 gl-flex">
            <span v-if="selectedRole.memberRoleId" class="gl-mr-3" data-testid="base-role">
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
            class="gl-flex"
            data-testid="permission"
          >
            <gl-icon name="check" class="gl-shrink-0" />
            <div class="gl-mx-3">
              <span data-testid="permission-name">
                {{ permission.name }}
              </span>
              <p class="gl-mt-2 gl-text-subtle" data-testid="permission-description">
                {{ permission.description }}
              </p>
            </div>
          </div>
        </dl>
      </div>

      <template #footer>
        <role-updater
          v-if="alert || isRoleChanged"
          #default="{ saveRole }"
          class="gl-flex gl-flex-col gl-gap-5"
          :member="member"
          :role="selectedRole"
          @busy="isSavingRole = $event"
          @alert="alert = $event"
          @reset="selectedRole = initialRole"
        >
          <gl-alert
            v-if="alert"
            :variant="alert.variant"
            :dismissible="alert.dismissible"
            @dismiss="alert = null"
          >
            {{ alert.message }}
          </gl-alert>

          <div v-if="isRoleChanged">
            <gl-button
              variant="confirm"
              :loading="isSavingRole"
              data-testid="save-button"
              @click="saveRole"
            >
              {{ s__('MemberRole|Update role') }}
            </gl-button>
            <gl-button
              class="gl-ml-2"
              :disabled="isSavingRole"
              data-testid="cancel-button"
              @click="setRole(initialRole)"
            >
              {{ __('Cancel') }}
            </gl-button>
          </div>
        </role-updater>
      </template>
    </gl-drawer>
  </members-table-cell>
</template>
