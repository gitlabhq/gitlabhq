<script>
import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { groupBy } from 'lodash';
import { s__ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { humanize } from '~/lib/utils/text_utility';
import { ACCESS_USER_ENUM } from '~/personal_access_tokens/constants';
import { groupPermissionsByResourceAndCategory } from '~/personal_access_tokens/utils';

export default {
  name: 'PersonalAccessTokenGranularPermissionsList',
  components: {
    CrudComponent,
    GlCollapsibleListbox,
    GlButton,
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
    selectedResources: {
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
  emits: ['input', 'remove-resource'],
  computed: {
    selected: {
      get() {
        return this.value;
      },
      set(newValue) {
        this.$emit('input', newValue);
      },
    },
    selectedResourcesGroupedByCategory() {
      if (!this.selectedResources.length) {
        return [];
      }

      const permissions = this.selectedResources.map((resource) =>
        this.permissions.find((p) => p.resource === resource),
      );

      return groupPermissionsByResourceAndCategory(permissions);
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
    listboxItems(resourceKey) {
      const items = this.permissionsByResource[resourceKey];

      if (!items) {
        return [];
      }

      return items?.map((item) => ({
        value: item.name,
        text: humanize(item.action),
      }));
    },
    dropdownText(resourceKey) {
      const items = this.listboxItems(resourceKey);

      // Filter items where value is in selected array and map to text
      const selectedTexts = items
        .filter((item) => this.selected.includes(item.value))
        .map((item) => item.text);

      return selectedTexts.length > 0
        ? selectedTexts.join(', ')
        : this.$options.i18n.selectPermissions;
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

    <template v-if="!selectedResources.length" #empty>
      <div class="gl-my-8 gl-text-center">
        {{ $options.i18n.noResourcesSelected }}
      </div>
    </template>

    <div
      v-for="category in selectedResourcesGroupedByCategory"
      :key="category.key"
      :data-testid="`category-${category.key}`"
    >
      <div class="gl-heading-5 gl-font-bold" data-testid="category-heading">
        {{ category.name }}
      </div>
      <div
        v-for="resource in category.resources"
        :key="resource.key"
        class="gl-mb-6 gl-flex gl-items-center gl-justify-between gl-gap-3"
      >
        <div class="gl-min-w-0 gl-flex-1">
          <div data-testid="resource-name">
            {{ resource.name }}
          </div>
          <div
            class="gl-mt-3 gl-line-clamp-2 gl-max-w-62 gl-text-sm gl-leading-20 gl-text-subtle"
            data-testid="resource-description"
          >
            {{ resource.description }}
          </div>
        </div>
        <div class="gl-flex gl-shrink-0 gl-items-center gl-gap-2">
          <gl-collapsible-listbox
            v-model="selected"
            :items="listboxItems(resource.key)"
            :toggle-text="dropdownText(resource.key)"
            multiple
          />
          <gl-button
            icon="close"
            category="tertiary"
            @click="$emit('remove-resource', resource.key)"
          />
        </div>
      </div>
      <hr />
    </div>
  </crud-component>
</template>
