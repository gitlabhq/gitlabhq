<script>
import { GlDrawer, GlBadge, GlSprintf, GlButton, GlIcon } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import MembersTableCell from 'ee_else_ce/members/components/table/members_table_cell.vue';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import MemberAvatar from './member_avatar.vue';

export default {
  components: {
    MemberAvatar,
    MembersTableCell,
    GlDrawer,
    GlBadge,
    GlSprintf,
    GlButton,
    GlIcon,
  },
  props: {
    member: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    viewPermissionsDocPath() {
      return helpPagePath('user/permissions');
    },
    customRole() {
      const customRoleId = this.member.accessLevel.memberRoleId;

      return this.member.customRoles?.find(({ memberRoleId }) => memberRoleId === customRoleId);
    },
    customRolePermissions() {
      return this.customRole?.permissions || [];
    },
  },
  getContentWrapperHeight,
  DRAWER_Z_INDEX,
  ACCESS_LEVEL_LABELS,
};
</script>

<template>
  <gl-drawer
    v-if="member"
    :header-height="$options.getContentWrapperHeight()"
    header-sticky
    :z-index="$options.DRAWER_Z_INDEX"
    open
    @close="$emit('close')"
  >
    <template #title>
      <h4 class="gl-m-0">{{ s__('MemberRole|Role details') }}</h4>
    </template>

    <!-- Do not remove this div, it's needed because every top-level element in the drawer's body will get padding and a
    bottom border applied to it, and we don't want that to be applied to everything. -->
    <div>
      <h5 class="gl-mr-6">{{ __('Account') }}</h5>
      <members-table-cell #default="{ memberType, isCurrentUser }" :member="member">
        <member-avatar
          :member-type="memberType"
          :is-current-user="isCurrentUser"
          :member="member"
        />
      </members-table-cell>

      <hr />

      <dl>
        <dt class="gl-mb-3" data-testid="role-header">{{ s__('MemberRole|Role') }}</dt>
        <dd data-testid="role-value">
          {{ member.accessLevel.stringValue }}
          <gl-badge v-if="customRole" size="sm" class="gl-ml-2">
            {{ s__('MemberRole|Custom role') }}
          </gl-badge>
        </dd>

        <template v-if="customRole">
          <dt class="gl-mt-6 gl-mb-3" data-testid="description-header">
            {{ s__('MemberRole|Description') }}
          </dt>
          <dd data-testid="description-value">
            {{ member.accessLevel.description }}
          </dd>
        </template>

        <dt class="gl-mt-6 gl-mb-3" data-testid="permissions-header">
          {{ s__('MemberRole|Permissions') }}
        </dt>
        <dd class="gl-display-flex gl-mb-5">
          <span v-if="customRole" class="gl-mr-3" data-testid="base-role">
            <gl-sprintf :message="s__('MemberRole|Base role: %{role}')">
              <template #role>
                {{ $options.ACCESS_LEVEL_LABELS[customRole.baseAccessLevel] }}
              </template>
            </gl-sprintf>
          </span>
          <gl-button
            :href="viewPermissionsDocPath"
            icon="external-link"
            variant="link"
            target="_blank"
          >
            {{ s__('MemberRole|View permissions') }}
          </gl-button>
        </dd>

        <div
          v-for="permission in customRolePermissions"
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
  </gl-drawer>
</template>
