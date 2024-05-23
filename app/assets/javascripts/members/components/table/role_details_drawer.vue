<script>
import { GlDrawer, GlButton } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import MembersTableCell from 'ee_else_ce/members/components/table/members_table_cell.vue';
import MemberAvatar from './member_avatar.vue';

export default {
  components: { MemberAvatar, MembersTableCell, GlDrawer, GlButton },
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
  },
  getContentWrapperHeight,
  DRAWER_Z_INDEX,
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
        <dd data-testid="role-value">{{ member.accessLevel.stringValue }}</dd>

        <dt class="gl-mt-6 gl-mb-3" data-testid="permissions-header">
          {{ s__('MemberRole|Permissions') }}
        </dt>
        <dd>
          <gl-button
            :href="viewPermissionsDocPath"
            icon="external-link"
            variant="link"
            target="_blank"
          >
            {{ s__('MemberRole|View permissions') }}
          </gl-button>
        </dd>
      </dl>
    </div>
  </gl-drawer>
</template>
