<script>
import { GlDrawer, GlButton, GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import {
  USERS_TYPE,
  GROUPS_TYPE,
  DEPLOY_KEYS_TYPE,
} from '~/vue_shared/components/list_selector/constants';
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
  ACCESS_LEVEL_NO_ACCESS_INTEGER,
  USERS_TYPE,
  GROUPS_TYPE,
  DEPLOY_KEYS_TYPE,
  i18n: {
    saveChanges: __('Save changes'),
    cancel: __('Cancel'),
  },
  components: {
    GlDrawer,
    GlButton,
    GlFormGroup,
    GlFormCheckbox,
    ItemsSelector: () =>
      import('ee_component/projects/settings/branch_rules/components/view/items_selector.vue'),
  },
  inject: {
    showEnterpriseAccessLevels: { default: false },
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
      required: false,
      default: () => [],
    },
    deployKeys: {
      type: Array,
      required: false,
      default: () => [],
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
    isPushAccessLevels: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      updatedGroups: this.groups,
      updatedUsers: this.users,
      updatedDeployKeys: this.deployKeys,
      isAdminSelected: null,
      isMaintainersSelected: null,
      isDevelopersAndMaintainersSelected: null,
      isNoOneSelected: null,
      isRuleUpdated: false,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    isSelfHosted() {
      return !window.gon?.dot_com;
    },
  },
  watch: {
    isOpen() {
      this.isAdminSelected = this.roles.includes(ACCESS_LEVEL_ADMIN_INTEGER);
      this.isMaintainersSelected = this.roles.includes(ACCESS_LEVEL_MAINTAINER_INTEGER);
      this.isDevelopersAndMaintainersSelected = this.roles.includes(ACCESS_LEVEL_DEVELOPER_INTEGER);
      this.isNoOneSelected = this.roles.includes(ACCESS_LEVEL_NO_ACCESS_INTEGER);

      this.updatedGroups = this.groups;
      this.updatedUsers = this.users;
      this.updatedDeployKeys = this.deployKeys;
    },
  },
  methods: {
    handleNoOneSelected() {
      this.isRuleUpdated = true;
      this.isAdminSelected = false;
      this.isMaintainersSelected = false;
      this.isDevelopersAndMaintainersSelected = false;
    },
    handleAccessLevelSelected() {
      this.isRuleUpdated = true;
      this.isNoOneSelected = false;
    },
    handleRuleDataUpdate(namespace, items) {
      this.isRuleUpdated = true;
      this[namespace] = items;
    },
    formatItemsData(items, keyName, type) {
      return items.map((item) => ({ [keyName]: convertToGraphQLId(type, item.id) }));
    },
    getRuleEditData() {
      const ruleEditRoles = [
        ...this.formatItemsData(this.updatedUsers, 'userId', 'User'), // eslint-disable-line @gitlab/require-i18n-strings
        ...this.formatItemsData(this.updatedGroups, 'groupId', 'Group'), // eslint-disable-line @gitlab/require-i18n-strings
        ...this.formatItemsData(this.updatedDeployKeys, 'deployKeyId', 'DeployKey'),
      ];
      let ruleEditAccessLevels = [];
      if (this.isAdminSelected) {
        ruleEditAccessLevels.push({ accessLevel: ACCESS_LEVEL_ADMIN_INTEGER });
      }
      if (this.isMaintainersSelected) {
        ruleEditAccessLevels.push({ accessLevel: ACCESS_LEVEL_MAINTAINER_INTEGER });
      }
      if (this.isDevelopersAndMaintainersSelected) {
        ruleEditAccessLevels.push({ accessLevel: ACCESS_LEVEL_DEVELOPER_INTEGER });
      }
      if (this.isNoOneSelected) {
        ruleEditAccessLevels = [{ accessLevel: ACCESS_LEVEL_NO_ACCESS_INTEGER }];
      }
      return [...ruleEditRoles, ...ruleEditAccessLevels];
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
      <h2 class="gl-my-0 gl-text-size-h2">{{ title }}</h2>
    </template>

    <template #default>
      <gl-form-group class="gl-border-none">
        <gl-form-checkbox
          v-if="isSelfHosted"
          v-model="isAdminSelected"
          data-testid="admins-role-checkbox"
          @change="handleAccessLevelSelected"
        >
          {{ $options.accessLevelsConfig[$options.ACCESS_LEVEL_ADMIN_INTEGER].accessLevelLabel }}
        </gl-form-checkbox>
        <gl-form-checkbox
          v-model="isMaintainersSelected"
          data-testid="maintainers-role-checkbox"
          @change="handleAccessLevelSelected"
        >
          {{
            $options.accessLevelsConfig[$options.ACCESS_LEVEL_MAINTAINER_INTEGER].accessLevelLabel
          }}
        </gl-form-checkbox>
        <gl-form-checkbox
          v-model="isDevelopersAndMaintainersSelected"
          data-testid="developers-role-checkbox"
          @change="handleAccessLevelSelected"
        >
          {{
            $options.accessLevelsConfig[$options.ACCESS_LEVEL_DEVELOPER_INTEGER].accessLevelLabel
          }}
        </gl-form-checkbox>
        <gl-form-checkbox
          v-model="isNoOneSelected"
          data-testid="no-one-role-checkbox"
          @change="handleNoOneSelected"
        >
          {{
            $options.accessLevelsConfig[$options.ACCESS_LEVEL_NO_ACCESS_INTEGER].accessLevelLabel
          }}
        </gl-form-checkbox>

        <template v-if="showEnterpriseAccessLevels">
          <items-selector
            :type="$options.USERS_TYPE"
            :items="formatItemsIds(users)"
            :users-options="$options.projectUsersOptions"
            data-testid="users-selector"
            @change="handleRuleDataUpdate('updatedUsers', $event)"
          />
          <items-selector
            :type="$options.GROUPS_TYPE"
            :items="formatItemsIds(groups)"
            data-testid="groups-selector"
            @change="handleRuleDataUpdate('updatedGroups', $event)"
          />
        </template>
        <items-selector
          v-if="isPushAccessLevels"
          :type="$options.DEPLOY_KEYS_TYPE"
          :items="formatItemsIds(deployKeys)"
          data-testid="deploy-keys-selector"
          @change="handleRuleDataUpdate('updatedDeployKeys', $event)"
        />
        <div class="gl-mt-5 gl-flex gl-gap-3">
          <gl-button
            variant="confirm"
            :disabled="!isRuleUpdated"
            :loading="isLoading"
            data-testid="save-allowed-to-merge"
            @click="editRule()"
          >
            {{ $options.i18n.saveChanges }}
          </gl-button>
          <gl-button
            variant="confirm"
            category="secondary"
            data-testid="cancel-btn"
            @click="$emit('close')"
          >
            {{ $options.i18n.cancel }}
          </gl-button>
        </div>
      </gl-form-group>
    </template>
  </gl-drawer>
</template>
