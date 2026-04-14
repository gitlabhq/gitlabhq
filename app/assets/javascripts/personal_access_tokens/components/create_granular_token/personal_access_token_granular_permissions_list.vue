<script>
import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
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
      validator: (value) => ['namespace', 'user'].includes(value),
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
  },
  i18n: {
    namespace: {
      permissionsTitle: s__('AccessTokens|Group and project'),
    },
    user: {
      permissionsTitle: s__('AccessTokens|User'),
    },
    noResourcesSelected: s__('AccessTokens|No resources added'),
    selectPermissions: s__('AccessTokens|Select permissions'),
  },
};
</script>
<template>
  <div class="gl-border gl-w-full gl-border-t-0 gl-p-5 lg:gl-border-l-0">
    <div class="gl-mb-2 gl-text-lg">{{ permissionsTitle }}</div>

    <template v-if="!selectedResources.length">
      <div class="gl-my-8 gl-text-center">
        {{ $options.i18n.noResourcesSelected }}
      </div>
    </template>

    <div
      v-for="category in selectedResourcesGroupedByCategory"
      :key="category.key"
      :data-testid="`category-${category.key}`"
    >
      <div class="gl-heading-5 gl-mt-4 gl-font-bold" data-testid="category-heading">
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
            class="gl-mt-1 gl-line-clamp-2 gl-max-w-62 gl-text-sm gl-leading-20 gl-text-subtle"
            data-testid="resource-description"
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
            @click="$emit('remove-resource', resource.key)"
          />
        </div>
      </div>
      <hr />
    </div>
  </div>
</template>
