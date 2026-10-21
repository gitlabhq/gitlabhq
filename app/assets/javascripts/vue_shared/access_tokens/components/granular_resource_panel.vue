<script>
import { GlSearchBoxByType, GlSkeletonLoader, GlSegmentedControl, GlBadge } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { ACCESS_SCOPES, ACCESS_SCOPE_KEYS } from '../constants';
import GranularResourcesList from './granular_resources_list.vue';

export default {
  name: 'GranularResourcePanel',
  components: {
    GlSearchBoxByType,
    GlSkeletonLoader,
    GlSegmentedControl,
    GlBadge,
    GranularResourcesList,
  },
  props: {
    scopes: {
      type: Array,
      required: false,
      default: () => ACCESS_SCOPES,
      validator: (scopes) =>
        scopes.length > 0 && scopes.every(({ key }) => ACCESS_SCOPE_KEYS.includes(key)),
    },
    activeBoundary: {
      type: String,
      required: true,
    },
    permissions: {
      type: Array,
      required: false,
      default: () => [],
    },
    selectedResources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['boundary-change', 'resources-input'],
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    accessOptions() {
      return this.scopes.map(({ key }) => ({
        value: key,
        text: this.$options.i18n[key].title,
        count: this.selectedResources[key]?.length ?? 0,
      }));
    },
    activeResources() {
      return this.selectedResources[this.activeBoundary] ?? [];
    },
    filteredPermissions() {
      if (!this.searchTerm) {
        return this.permissions;
      }

      const term = this.searchTerm.toLowerCase();

      return this.permissions.filter((permission) =>
        ['description', 'category'].some((field) => permission[field].toLowerCase().includes(term)),
      );
    },
  },
  i18n: {
    accessLabel: s__('AccessTokens|Resource access'),
    searchPlaceholder: s__('AccessTokens|Search for resources to add'),
    noResourcesFound: __('No resources found'),
    namespace: {
      title: s__('AccessTokens|Group and project'),
    },
    user: {
      title: s__('AccessTokens|User'),
    },
    instance: {
      title: s__('AccessTokens|Global'),
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-4 gl-flex gl-flex-wrap gl-items-center gl-gap-3">
      <span class="gl-font-bold">{{ $options.i18n.accessLabel }}</span>
      <gl-segmented-control
        :value="activeBoundary"
        :options="accessOptions"
        :aria-label="$options.i18n.accessLabel"
        data-testid="access-selector"
        @input="$emit('boundary-change', $event)"
      >
        <template #button-content="{ text, count }">
          {{ text }}
          <gl-badge v-if="count" class="gl-ml-2" size="sm" data-testid="boundary-count">
            {{ count }}
          </gl-badge>
        </template>
      </gl-segmented-control>
    </div>

    <gl-search-box-by-type
      v-model="searchTerm"
      :placeholder="$options.i18n.searchPlaceholder"
      class="gl-mb-4"
    />

    <gl-skeleton-loader v-if="isLoading" />
    <granular-resources-list
      v-else-if="filteredPermissions.length"
      :key="activeBoundary"
      :value="activeResources"
      :permissions="filteredPermissions"
      :scope="activeBoundary"
      :is-filtering="Boolean(searchTerm)"
      @input="$emit('resources-input', $event)"
    />
    <div v-else class="gl-my-4 gl-text-center gl-text-subtle">
      {{ $options.i18n.noResourcesFound }}
    </div>
  </div>
</template>
