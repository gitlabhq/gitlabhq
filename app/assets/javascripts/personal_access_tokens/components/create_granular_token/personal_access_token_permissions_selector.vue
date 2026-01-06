<script>
import { GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
import { intersection, some } from 'lodash';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import getAccessTokenPermissions from '~/personal_access_tokens/graphql/get_access_token_permissions.query.graphql';
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
    filteredPermissionsByAccess() {
      return this.permissions.filter(
        ({ boundaries }) => intersection(['GROUP', 'PROJECT'], boundaries).length > 0,
      );
    },
    filteredPermissions() {
      if (!this.permissions) {
        return [];
      }

      if (!this.searchTerm) {
        return this.filteredPermissionsByAccess;
      }

      return this.filteredPermissionsByAccess.filter((permission) =>
        some(['description', 'category'], (field) =>
          permission[field].toLowerCase().includes(this.searchTerm.toLowerCase()),
        ),
      );
    },
  },
  methods: {
    handleResourceChange(resource) {
      const exists = this.selectedResources.includes(resource);

      // if a resource doesn't exist i.e. is unchecked,
      // remove any selected permissions
      if (!exists) {
        this.selectedPermissions = this.selectedPermissions.filter(
          (perm) => !perm.endsWith(`_${resource}`),
        );

        this.$emit('input', this.selectedPermissions);
      }
    },
  },
  i18n: {
    group: {
      resourceTitle: s__('AccessTokens|Group and project resources'),
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
      <div class="gl-border gl-mt-5 gl-w-full gl-rounded-lg gl-p-4 lg:gl-w-1/3">
        <h3 class="gl-heading-5">
          {{ $options.i18n.group.resourceTitle }}
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
          @change="handleResourceChange"
        />
        <div v-else class="gl-my-4 gl-text-center gl-text-subtle">
          {{ $options.i18n.noResourcesFound }}
        </div>
      </div>

      <personal-access-token-granular-permissions-list
        v-model="selectedPermissions"
        :permissions="filteredPermissions"
        :resources="selectedResources"
        class="gl-mt-5 gl-w-full lg:gl-w-2/3"
        @input="$emit('input', $event)"
      />
    </div>

    <div v-if="error" class="gl-font-sm gl-mt-2 gl-text-red-500">
      {{ error }}
    </div>
  </div>
</template>
