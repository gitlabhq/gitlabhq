<script>
import { GlDrawer, GlButton, GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  ACCESS_LEVEL_DEVELOPER_INTEGER,
  ACCESS_LEVEL_MAINTAINER_INTEGER,
  ACCESS_LEVEL_ADMIN_INTEGER,
  ACCESS_LEVEL_NO_ACCESS_INTEGER,
} from '~/access_level/constants';
import { projectUsersOptions, accessLevelsConfig } from './constants';

export default {
  DRAWER_Z_INDEX,
  projectUsersOptions,
  accessLevelsConfig,
  ACCESS_LEVEL_DEVELOPER_INTEGER,
  ACCESS_LEVEL_MAINTAINER_INTEGER,
  ACCESS_LEVEL_ADMIN_INTEGER,
  components: {
    GlDrawer,
    GlButton,
    GlFormGroup,
    GlFormCheckbox,
    ItemsSelector: () =>
      import('ee_component/projects/settings/branch_rules/components/view/items_selector.vue'),
  },
  props: {
    isOpen: {
      type: Boolean,
      required: true,
    },
    users: {
      type: Array,
      required: false,
      default: () => [],
    },
    groups: {
      type: Array,
      required: false,
      default: () => [],
    },
    roles: {
      type: Array,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    groupId: {
      type: Number,
      required: false,
      default: null,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      updatedGroups: this.groups,
      updatedUsers: this.users,
      isAdminSelected: null,
      isMaintainersSelected: null,
      isDevelopersAndMaintainersSelected: null,
      isRuleUpdated: false,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    isNoOneSelected() {
      return (
        !this.isAdminSelected &&
        !this.isMaintainersSelected &&
        !this.isDevelopersAndMaintainersSelected
      );
    },
  },
  watch: {
    isOpen() {
      this.isAdminSelected = this.roles.includes(ACCESS_LEVEL_ADMIN_INTEGER);
      this.isMaintainersSelected = this.roles.includes(ACCESS_LEVEL_MAINTAINER_INTEGER);
      this.isDevelopersAndMaintainersSelected = this.roles.includes(ACCESS_LEVEL_DEVELOPER_INTEGER);

      this.updatedGroups = this.groups;
      this.updatedUsers = this.users;
    },
  },
  methods: {
    handleRuleDataUpdate(namespace, items) {
      this.isRuleUpdated = true;
      this[namespace] = items;
    },
    formatItemsData(items, keyName, type) {
      return items.map((item) => ({ [keyName]: convertToGraphQLId(type, item.id) }));
    },
    getRuleEditData() {
      let ruleEditData = [
        ...this.formatItemsData(this.updatedUsers, 'userId', 'User'), // eslint-disable-line @gitlab/require-i18n-strings
        ...this.formatItemsData(this.updatedGroups, 'groupId', 'Group'), // eslint-disable-line @gitlab/require-i18n-strings
      ];
      if (this.isAdminSelected) {
        ruleEditData.push({ accessLevel: ACCESS_LEVEL_ADMIN_INTEGER });
      }
      if (this.isMaintainersSelected) {
        ruleEditData.push({ accessLevel: ACCESS_LEVEL_MAINTAINER_INTEGER });
      }
      if (this.isDevelopersAndMaintainersSelected) {
        ruleEditData.push({ accessLevel: ACCESS_LEVEL_DEVELOPER_INTEGER });
      }
      if (this.isNoOneSelected) {
        ruleEditData = [{ accessLevel: ACCESS_LEVEL_NO_ACCESS_INTEGER }];
      }
      return ruleEditData;
    },
    formatItemsIds(items) {
      return items.map((item) => ({ ...item, id: getIdFromGraphQLId(item.id) }));
    },
    editRule() {
      this.$emit('editRule', this.getRuleEditData());
    },
  },
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    :open="isOpen"
    @ok="editRule()"
    v-on="$listeners"
  >
    <template #title>
      <h2 class="gl-mt-0 gl-text-size-h2">{{ title }}</h2>
    </template>

    <template #header>
      <gl-button
        variant="confirm"
        :disabled="!isRuleUpdated"
        :loading="isLoading"
        data-testid="save-allowed-to-merge"
        @click="editRule()"
      >
        {{ __('Save changes') }}
      </gl-button>
      <gl-button variant="confirm" category="secondary" @click="$emit('close')">
        {{ __('Cancel') }}
      </gl-button>
    </template>
    <template #default>
      <gl-form-group class="gl-border-none">
        <gl-form-checkbox v-model="isAdminSelected" @change="isRuleUpdated = true">
          {{ $options.accessLevelsConfig[$options.ACCESS_LEVEL_ADMIN_INTEGER].accessLevelLabel }}
        </gl-form-checkbox>
        <gl-form-checkbox v-model="isMaintainersSelected" @change="isRuleUpdated = true">
          {{
            $options.accessLevelsConfig[$options.ACCESS_LEVEL_MAINTAINER_INTEGER].accessLevelLabel
          }}
        </gl-form-checkbox>
        <gl-form-checkbox
          v-model="isDevelopersAndMaintainersSelected"
          @change="isRuleUpdated = true"
        >
          {{
            $options.accessLevelsConfig[$options.ACCESS_LEVEL_DEVELOPER_INTEGER].accessLevelLabel
          }}
        </gl-form-checkbox>

        <items-selector
          type="users"
          :items="formatItemsIds(users)"
          :users-options="$options.projectUsersOptions"
          data-testid="users-selector"
          @change="handleRuleDataUpdate('updatedUsers', $event)"
        />
        <items-selector
          type="groups"
          disable-namespace-dropdown
          is-project-scoped
          :items="formatItemsIds(groups)"
          data-testid="groups-selector"
          @change="handleRuleDataUpdate('updatedGroups', $event)"
        />
      </gl-form-group>
    </template>
  </gl-drawer>
</template>
