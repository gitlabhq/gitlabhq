<script>
import { GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
import { intersection, some } from 'lodash';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import getAccessTokenPermissions from '~/personal_access_tokens/graphql/get_access_token_permissions.query.graphql';
import { ACCESS_USER_ENUM } from '~/personal_access_tokens/constants';
import PersonalAccessTokenResourcesList from './personal_access_token_resources_list.vue';
import PersonalAccessTokenGranularPermissionsList from './personal_access_token_granular_permissions_list.vue';

export default {
  name: 'PersonalAccessTokenPermissionsSelector',
  components: {
    GlSearchBoxByType,
    GlSkeletonLoader,
    PersonalAccessTokenResourcesList,
    PersonalAccessTokenGranularPermissionsList,
  },
  props: {
    targetBoundaries: {
      type: Array,
      required: true,
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['input'],
  data() {
    return {
      permissions: [],
      selectedResources: [],
      selectedPermissions: [],
      searchTerm: '',
    };
  },
  apollo: {
    permissions: {
      query: getAccessTokenPermissions,
      update(data) {
        return data?.accessTokenPermissions || [];
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
    isLoading() {
      return Boolean(this.$apollo.queries.permissions.loading);
    },
    isUserScope() {
      return this.targetBoundaries.includes(ACCESS_USER_ENUM);
    },
    resourceTitle() {
      return this.isUserScope
        ? this.$options.i18n.user.resourceTitle
        : this.$options.i18n.namespace.resourceTitle;
    },
    filteredPermissionsByBoundary() {
      return this.permissions.filter(
        ({ boundaries }) => intersection(this.targetBoundaries, boundaries).length > 0,
      );
    },
    filteredPermissions() {
      if (!this.permissions) {
        return [];
      }

      if (!this.searchTerm) {
        return this.filteredPermissionsByBoundary;
      }

      return this.filteredPermissionsByBoundary.filter((permission) =>
        some(['description', 'category'], (field) =>
          permission[field].toLowerCase().includes(this.searchTerm.toLowerCase()),
        ),
      );
    },
  },
  watch: {
    selectedResources(newResources, oldResources) {
      this.updateSelectedResources(newResources, oldResources);
    },
  },
  methods: {
    updateSelectedResources(newResources, oldResources) {
      // find resources that were removed
      const removedResources = oldResources.filter((resource) => !newResources.includes(resource));

      // remove permissions associated with the removed resources
      if (removedResources.length > 0) {
        this.selectedPermissions = this.selectedPermissions.filter(
          (permission) => !removedResources.some((resource) => permission.endsWith(`_${resource}`)),
        );

        // emit updated permissions after cleanup
        this.$emit('input', this.selectedPermissions);
      }
    },
    handleRemoveResource(resourceToRemove) {
      this.selectedResources = this.selectedResources.filter(
        (selectedResource) => selectedResource !== resourceToRemove,
      );
    },
  },
  i18n: {
    namespace: {
      resourceTitle: s__('AccessTokens|Group and project resources'),
    },
    user: {
      resourceTitle: s__('AccessTokens|User resources'),
    },
    searchPlaceholder: s__('AccessTokens|Search for resources to add'),
    noResourcesFound: __('No resources found'),
    fetchError: s__('AccessTokens|Error loading permissions. Please refresh page.'),
  },
};
</script>

<template>
  <div>
    <div class="gl-flex gl-flex-col lg:gl-flex-row lg:gl-gap-5">
      <div class="gl-border gl-mt-5 gl-w-full gl-rounded-lg gl-p-4 lg:gl-min-h-75 lg:gl-w-1/3">
        <h3 class="gl-heading-5">
          {{ resourceTitle }}
        </h3>

        <gl-search-box-by-type
          v-model="searchTerm"
          :placeholder="$options.i18n.searchPlaceholder"
          class="gl-mb-6"
        />

        <gl-skeleton-loader v-if="isLoading" />
        <personal-access-token-resources-list
          v-else-if="filteredPermissions.length"
          v-model="selectedResources"
          :permissions="filteredPermissions"
        />
        <div v-else class="gl-my-4 gl-text-center gl-text-subtle">
          {{ $options.i18n.noResourcesFound }}
        </div>
      </div>

      <personal-access-token-granular-permissions-list
        v-model="selectedPermissions"
        :permissions="filteredPermissionsByBoundary"
        :selected-resources="selectedResources"
        :target-boundaries="targetBoundaries"
        class="gl-mt-5 gl-w-full lg:gl-w-2/3"
        @input="$emit('input', $event)"
        @remove-resource="handleRemoveResource"
      />
    </div>

    <div v-if="error" class="gl-font-sm gl-mt-2 gl-text-red-500">
      {{ error }}
    </div>
  </div>
</template>
