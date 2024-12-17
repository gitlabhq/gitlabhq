<script>
import { GlCollapsibleListbox, GlBadge, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import { ACCESS_LEVEL_PLANNER_STRING } from '~/access_level/constants';

export default {
  components: { GlCollapsibleListbox, GlBadge, GlPopover },
  inject: {
    manageMemberRolesPath: { default: null },
  },
  i18n: {
    plannerRoleDescription: s__(
      'MemberRole|The Planner role is a hybrid of the existing Guest and Reporter roles but designed for users who need access to planning workflows.',
    ),
  },
  plannerRole: ACCESS_LEVEL_PLANNER_STRING,
  badgeId: 'planner-role-badge',
  props: {
    roles: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    headerText: {
      type: String,
      required: false,
      default: s__('MemberRole|Change role'),
    },
  },
  computed: {
    manageRolesText() {
      return this.manageMemberRolesPath ? s__('MemberRole|Manage roles') : '';
    },
  },
  methods: {
    navigateToManageMemberRolesPage() {
      visitUrl(this.manageMemberRolesPath);
    },
    emitRole(selectedValue) {
      const role = this.roles.flatten.find(({ value }) => value === selectedValue);
      this.$emit('input', role);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :header-text="headerText"
    :reset-button-label="manageRolesText"
    :items="roles.formatted"
    :selected="value && value.value"
    :loading="loading"
    block
    @reset="navigateToManageMemberRolesPage"
    @select="emitRole"
  >
    <template #list-item="{ item }">
      <div
        class="gl-line-clamp-2 gl-flex gl-justify-between"
        :class="{ 'gl-font-bold': item.memberRoleId }"
        data-testid="role-data"
      >
        <span data-testid="role-name">{{ item.text }}</span>
        <template v-if="$options.plannerRole === item.value">
          <gl-badge :id="$options.badgeId" variant="info" class="gl-ml-2">
            {{ __('New') }}
          </gl-badge>
          <gl-popover :target="$options.badgeId">
            {{ $options.i18n.plannerRoleDescription }}
          </gl-popover>
        </template>
      </div>
      <div
        v-if="item.memberRoleId"
        class="gl-mt-1 gl-line-clamp-2 gl-text-sm"
        data-testid="role-description"
      >
        <span v-if="item.description" class="gl-text-subtle">{{ item.description }}</span>
        <span v-else class="gl-text-subtle">{{ s__('MemberRole|No description') }}</span>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
