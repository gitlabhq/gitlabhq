<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { groupBy } from 'lodash';
import { s__ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

export default {
  name: 'PersonalAccessTokenGranularPermissionsList',
  components: {
    CrudComponent,
    GlCollapsibleListbox,
  },
  props: {
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
  },
  methods: {
    listboxItems(resource) {
      return this.permissionsByResource[resource];
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
    group: {
      permissionsTitle: s__('AccessTokens|Group and project permissions'),
      permissionsDescription: s__(
        'AccessTokens|Grant permissions only to specific resources in your groups or projects.',
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
      {{ $options.i18n.group.permissionsTitle }}
    </template>

    <template #description>
      {{ $options.i18n.group.permissionsDescription }}
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
