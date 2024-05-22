<script>
import { GlDrawer, GlButton, GlFormGroup } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { projectUsersOptions } from './constants';

export default {
  DRAWER_Z_INDEX,
  projectUsersOptions,
  components: {
    GlDrawer,
    GlButton,
    GlFormGroup,
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
      required: true,
    },
    groups: {
      type: Array,
      required: true,
    },
    roles: {
      type: Array,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      updatedGroups: [],
      updatedUsers: [],
      isRuleUpdated: false,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
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
      return [
        ...this.formatItemsData(this.updatedUsers, 'userId', 'User'), // eslint-disable-line @gitlab/require-i18n-strings
      ];
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
      <h2 class="gl-font-size-h2 gl-mt-0">{{ title }}</h2>
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
        <items-selector
          type="users"
          :items="formatItemsIds(users)"
          is-project-only-namespace
          :users-options="$options.projectUsersOptions"
          @change="handleRuleDataUpdate('updatedUsers', $event)"
        />
      </gl-form-group>
    </template>
  </gl-drawer>
</template>
