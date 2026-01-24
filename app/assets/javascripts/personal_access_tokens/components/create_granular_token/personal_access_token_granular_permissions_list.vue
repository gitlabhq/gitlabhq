<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { groupBy } from 'lodash';
import { s__ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { ACCESS_USER_ENUM } from '~/personal_access_tokens/constants';

export default {
  name: 'PersonalAccessTokenGranularPermissionsList',
  components: {
    CrudComponent,
    GlCollapsibleListbox,
  },
  props: {
    targetBoundaries: {
      type: Array,
      required: true,
    },
    permissions: {
      type: Array,
      required: false,
      default: () => [],
    },
    resources: {
      type: Array,
      required: false,
      default: () => [],
    },
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['input'],
  computed: {
    selected: {
      get() {
        return this.value;
      },
      set(newValue) {
        this.$emit('input', newValue);
      },
    },
    permissionsByResource() {
      return groupBy(this.permissions, 'resource');
    },
    isUserScope() {
      return this.targetBoundaries.includes(ACCESS_USER_ENUM);
    },
    permissionsTitle() {
      return this.isUserScope
        ? this.$options.i18n.user.permissionsTitle
        : this.$options.i18n.namespace.permissionsTitle;
    },
    permissionsDescription() {
      return this.isUserScope
        ? this.$options.i18n.user.permissionsDescription
        : this.$options.i18n.namespace.permissionsDescription;
    },
  },
  methods: {
    listboxItems(resource) {
      const items = this.permissionsByResource[resource];

      if (!items) {
        return [];
      }

      return items?.map((item) => ({
        ...item,
        text: this.removeUnderscore(item.text),
      }));
    },
    dropdownText(resource) {
      // permissions is an array of all selected permissions -> [read_badge, read_member]
      // find the list of selected permissions for the resource first
      const permissions = this.selected
        .filter((perm) => perm.endsWith(`_${resource}`))
        .map((perm) => perm.split('_')[0]);

      if (permissions.length) {
        return permissions.map(capitalizeFirstCharacter).join(', ');
      }

      return this.$options.i18n.selectPermissions;
    },
    removeUnderscore(string) {
      return string.replace(/_/g, ' ');
    },
  },
  i18n: {
    namespace: {
      permissionsTitle: s__('AccessTokens|Group and project permissions'),
      permissionsDescription: s__(
        'AccessTokens|Grant permissions only to specific resources in your groups or projects.',
      ),
    },
    user: {
      permissionsTitle: s__('AccessTokens|User permissions'),
      permissionsDescription: s__(
        'AccessTokens|Grant permissions to resources in your GitLab user account.',
      ),
    },
    noResourcesSelected: s__('AccessTokens|No resources selected'),
    selectPermissions: s__('AccessTokens|Select permissions'),
  },
};
</script>
<template>
  <crud-component class="gl-w-2/3">
    <template #title>
      {{ permissionsTitle }}
    </template>

    <template #description>
      {{ permissionsDescription }}
    </template>

    <template v-if="!resources.length" #empty>
      <div class="gl-my-8 gl-text-center">
        {{ $options.i18n.noResourcesSelected }}
      </div>
    </template>

    <div
      v-for="resource in resources"
      :key="resource"
      class="gl-mb-4 gl-flex gl-items-center gl-justify-between gl-gap-3"
    >
      <div class="gl-capitalize">{{ removeUnderscore(resource) }}</div>

      <gl-collapsible-listbox
        v-model="selected"
        :items="listboxItems(resource)"
        :toggle-text="dropdownText(resource)"
        multiple
        class="gl-capitalize"
      />
    </div>
  </crud-component>
</template>
