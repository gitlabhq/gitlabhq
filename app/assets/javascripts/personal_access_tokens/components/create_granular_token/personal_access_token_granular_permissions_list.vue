<script>
import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { ACCESS_SCOPE_KEYS } from '~/personal_access_tokens/constants';
import { groupPermissionsByResourceAndCategory } from '~/personal_access_tokens/utils';

export default {
  name: 'PersonalAccessTokenGranularPermissionsList',
  components: {
    GlCollapsibleListbox,
    GlButton,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
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
    scope: {
      type: String,
      required: true,
      validator: (value) => ACCESS_SCOPE_KEYS.includes(value),
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
      // permissions is a flat list of permissions filtered by boundary
      // filter them by selectedResources & then group by category for rendering
      if (!this.selectedResources.length) {
        return [];
      }

      // map over selectedResources to preserve their order, rather than filtering permissions
      // which would return results in permissions array order instead.
      const permissionsForSelectedResources = this.selectedResources.flatMap((resource) =>
        this.permissions.filter((p) => p.resource === resource),
      );

      return groupPermissionsByResourceAndCategory(permissionsForSelectedResources);
    },
    permissionsTitle() {
      return this.$options.i18n[this.scope].permissionsTitle;
    },
  },
  methods: {
    listboxItems(actions) {
      return actions.map(({ key, name }) => ({ value: key, text: name }));
    },
    dropdownText(actions) {
      const selectedNames = actions
        .filter((action) => this.selected.includes(action.key))
        .map((action) => action.name)
        .join(', ');

      return selectedNames || this.$options.i18n.selectPermissions;
    },
    removeResourceAriaLabel(resourceName) {
      return sprintf(this.$options.i18n.removeResource, { resource: resourceName });
    },
  },
  i18n: {
    namespace: {
      permissionsTitle: s__('AccessTokens|Group and project'),
    },
    user: {
      permissionsTitle: s__('AccessTokens|User'),
    },
    instance: {
      permissionsTitle: s__('AccessTokens|Global'),
    },
    resource: s__('AccessTokens|Resource'),
    permissions: s__('AccessTokens|Permissions'),
    noResourcesSelected: s__(
      'AccessTokens|No resources selected. Add resources to set permissions.',
    ),
    selectPermissions: s__('AccessTokens|Select permissions'),
    removeResource: s__('AccessTokens|Remove %{resource}'),
  },
};
</script>
<template>
  <div
    class="gl-border-b-1 gl-border-b-section gl-py-5 gl-border-b-solid"
    data-testid="granular-permissions-section"
  >
    <div class="gl-mb-3 gl-text-lg">{{ permissionsTitle }}</div>

    <div class="gl-flex gl-items-center gl-justify-between gl-gap-3 gl-pb-3 gl-font-bold">
      <span>{{ $options.i18n.resource }}</span>
      <span>{{ $options.i18n.permissions }}</span>
    </div>

    <div
      v-if="!selectedResources.length"
      class="gl-py-6 gl-text-center gl-text-subtle"
      data-testid="empty-state"
    >
      {{ $options.i18n.noResourcesSelected }}
    </div>

    <div
      v-for="category in selectedResourcesGroupedByCategory"
      v-else
      :key="category.key"
      data-testid="selected-category"
    >
      <div class="gl-heading-5 gl-mt-4 gl-font-bold" data-testid="selected-category-heading">
        {{ category.name }}
      </div>
      <div
        v-for="resource in category.resources"
        :key="resource.key"
        class="gl-mb-6 gl-flex gl-items-center gl-justify-between gl-gap-3"
        data-testid="selected-resource"
      >
        <div class="gl-min-w-0 gl-flex-1">
          <div data-testid="selected-resource-name">
            {{ resource.name }}
          </div>
          <div
            class="gl-mt-1 gl-line-clamp-2 gl-max-w-62 gl-text-sm gl-leading-20 gl-text-subtle"
            data-testid="selected-resource-description"
          >
            {{ resource.description }}
          </div>
        </div>
        <div class="gl-flex gl-shrink-0 gl-items-center gl-gap-2">
          <gl-collapsible-listbox
            v-model="selected"
            :items="listboxItems(resource.actions)"
            :toggle-text="dropdownText(resource.actions)"
            placement="bottom-end"
            multiple
          />
          <gl-button
            icon="close"
            category="tertiary"
            :aria-label="removeResourceAriaLabel(resource.name)"
            @click="$emit('remove-resource', resource.key)"
          />
        </div>
      </div>
    </div>
  </div>
</template>
