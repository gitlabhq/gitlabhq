<script>
import { GlTab, GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
import { intersection, some } from 'lodash-es';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import getAccessTokenPermissions from '~/personal_access_tokens/graphql/get_access_token_permissions.query.graphql';
import { ACCESS_USER_ENUM } from '~/personal_access_tokens/constants';
import PersonalAccessTokenResourcesList from './personal_access_token_resources_list.vue';
import PersonalAccessTokenGranularPermissionsList from './personal_access_token_granular_permissions_list.vue';

export default {
  name: 'PersonalAccessTokenPermissionsSelector',
  components: {
    GlTab,
    GlSearchBoxByType,
    GlSkeletonLoader,
    PersonalAccessTokenResourcesList,
    PersonalAccessTokenGranularPermissionsList,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    targetBoundaries: {
      type: Array,
      required: true,
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
    aiPermissions: {
      type: Object,
      required: false,
      default: () => ({ suggested: [], removed: [] }),
    },
  },
  emits: ['input'],
  data() {
    return {
      permissions: [],
      selectedResources: [],
      searchTerm: '',
    };
  },
  apollo: {
    permissions: {
      query: getAccessTokenPermissions,
      update(data) {
        const all = data?.accessTokenPermissions || [];
        return all.filter(
          ({ boundaries }) => intersection(this.targetBoundaries, boundaries).length > 0,
        );
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.fetchError,
          captureError: true,
          error,
        });
      },
    },
  },
  computed: {
    selectedPermissions: {
      get() {
        return this.value ?? [];
      },
      set(val) {
        this.$emit('input', val);
      },
    },
    isLoading() {
      return Boolean(this.$apollo.queries.permissions.loading);
    },
    isUserScope() {
      return this.targetBoundaries.includes(ACCESS_USER_ENUM);
    },
    scope() {
      return this.isUserScope ? 'user' : 'namespace';
    },
    tabTitle() {
      return this.$options.i18n[this.scope].tabTitle;
    },
    permissionsFilteredBySearch() {
      if (!this.permissions) {
        return [];
      }

      if (!this.searchTerm) {
        return this.permissions;
      }

      return this.permissions.filter((permission) =>
        some(['description', 'category'], (field) =>
          permission[field].toLowerCase().includes(this.searchTerm.toLowerCase()),
        ),
      );
    },
  },
  watch: {
    selectedResources(newResources, oldResources) {
      if (!oldResources.length) return;

      const removedResources = oldResources.filter((resource) => !newResources.includes(resource));

      if (removedResources.length > 0) {
        this.removePermissionsForResources(removedResources);
      }
    },
    value(newPermissions) {
      // when a token is duplicated, parent passes down selected permissions
      // select associated resources for those permissions
      this.syncSelectedResources(newPermissions);
    },
    permissions() {
      this.syncSelectedResources(this.value);
      this.applyAiSuggestedPermissions(this.aiPermissions.suggested);
    },
    'aiPermissions.suggested': {
      immediate: true,
      handler(suggested) {
        this.applyAiSuggestedPermissions(suggested);
      },
    },
    'aiPermissions.removed': {
      immediate: true,
      handler(removed) {
        this.applyAiRemovedPermissions(removed);
      },
    },
  },
  methods: {
    handleRemoveResource(resourceToRemove) {
      this.selectedResources = this.selectedResources.filter(
        (resource) => resource !== resourceToRemove,
      );
    },
    removePermissionsForResources(removedResources) {
      const permissionsToRemove = this.permissions
        .filter((permission) => removedResources.includes(permission.resource))
        .map((permission) => permission.name);

      this.selectedPermissions = this.selectedPermissions.filter(
        (permission) => !permissionsToRemove.includes(permission),
      );
    },
    getMatchingPermissions(permissionNames) {
      if (!permissionNames.length || !this.permissions.length) return [];

      const namesSet = new Set(permissionNames);

      return this.permissions.filter((p) => namesSet.has(p.name));
    },
    syncSelectedResources(permissionNames) {
      const matching = this.getMatchingPermissions(permissionNames);
      if (!matching.length) return;

      this.selectedResources = [
        ...new Set([...this.selectedResources, ...matching.map((p) => p.resource)]),
      ];
    },
    applyAiSuggestedPermissions(suggested) {
      const matching = this.getMatchingPermissions(suggested);
      if (!matching.length) return;

      this.selectedResources = [
        ...new Set([...this.selectedResources, ...matching.map((p) => p.resource)]),
      ];
      this.selectedPermissions = [
        ...new Set([...this.selectedPermissions, ...matching.map((p) => p.name)]),
      ];
    },
    applyAiRemovedPermissions(removed) {
      if (!removed.length) return;

      const removalSet = new Set(removed);

      this.selectedPermissions = this.selectedPermissions.filter((name) => !removalSet.has(name));
    },
  },
  i18n: {
    namespace: {
      tabTitle: s__('AccessTokens|Group and project'),
    },
    user: {
      tabTitle: s__('AccessTokens|User'),
    },
    searchPlaceholder: s__('AccessTokens|Search for resources to add'),
    noResourcesFound: __('No resources found'),
    fetchError: s__('AccessTokens|Error loading permissions. Please refresh page.'),
  },
};
</script>

<template>
  <gl-tab :title="tabTitle" :tab-count="selectedResources.length">
    <div class="gl-flex gl-flex-col lg:gl-flex-row">
      <div class="gl-border gl-w-full gl-border-t-0 gl-p-4 lg:gl-min-h-75 lg:gl-w-2/5">
        <gl-search-box-by-type
          v-model="searchTerm"
          :placeholder="$options.i18n.searchPlaceholder"
          class="gl-mb-4"
        />

        <gl-skeleton-loader v-if="isLoading" />
        <personal-access-token-resources-list
          v-else-if="permissionsFilteredBySearch.length"
          v-model="selectedResources"
          :permissions-filtered-by-search="permissionsFilteredBySearch"
          :scope="scope"
        />
        <div v-else class="gl-my-4 gl-text-center gl-text-subtle">
          {{ $options.i18n.noResourcesFound }}
        </div>
      </div>

      <personal-access-token-granular-permissions-list
        v-model="selectedPermissions"
        :permissions="permissions"
        :selected-resources="selectedResources"
        :scope="scope"
        @remove-resource="handleRemoveResource"
      />
    </div>
    <div v-if="error" class="invalid-feedback gl-block gl-pb-4">{{ error }}</div>
  </gl-tab>
</template>
