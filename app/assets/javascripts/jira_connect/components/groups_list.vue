<script>
import { GlLoadingIcon, GlPagination, GlAlert, GlSearchBoxByType } from '@gitlab/ui';
import { fetchGroups } from '~/jira_connect/api';
import { DEFAULT_GROUPS_PER_PAGE, MINIMUM_SEARCH_TERM_LENGTH } from '~/jira_connect/constants';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import GroupsListItem from './groups_list_item.vue';

export default {
  components: {
    GlLoadingIcon,
    GlPagination,
    GlAlert,
    GlSearchBoxByType,
    GroupsListItem,
  },
  inject: {
    groupsPath: {
      default: '',
    },
  },
  data() {
    return {
      groups: [],
      isLoadingInitial: true,
      isLoadingMore: false,
      page: 1,
      totalItems: 0,
      errorMessage: null,
      searchTerm: '',
    };
  },
  computed: {
    showPagination() {
      return this.totalItems > this.$options.DEFAULT_GROUPS_PER_PAGE && this.groups.length > 0;
    },
  },
  mounted() {
    return this.loadGroups().finally(() => {
      this.isLoadingInitial = false;
    });
  },
  methods: {
    loadGroups() {
      // fetchGroups returns no results for search terms 0 < {length} < 3.
      // The desired UX is to return the unfiltered results for searches {length} < 3.
      // Here, we set the search to an empty string if {length} < 3
      const search = this.searchTerm?.length < MINIMUM_SEARCH_TERM_LENGTH ? '' : this.searchTerm;

      this.isLoadingMore = true;
      return fetchGroups(this.groupsPath, {
        page: this.page,
        perPage: this.$options.DEFAULT_GROUPS_PER_PAGE,
        search,
      })
        .then((response) => {
          const { page, total } = parseIntPagination(normalizeHeaders(response.headers));
          this.page = page;
          this.totalItems = total;
          this.groups = response.data;
        })
        .catch(() => {
          this.errorMessage = s__('Integrations|Failed to load namespaces. Please try again.');
        })
        .finally(() => {
          this.isLoadingMore = false;
        });
    },
    onGroupSearch(searchTerm) {
      // keep a copy of the search term for pagination
      this.searchTerm = searchTerm;
      // reset the current page
      this.page = 1;
      return this.loadGroups();
    },
  },
  DEFAULT_GROUPS_PER_PAGE,
};
</script>

<template>
  <div>
    <gl-alert v-if="errorMessage" class="gl-mb-5" variant="danger" @dismiss="errorMessage = null">
      {{ errorMessage }}
    </gl-alert>

    <gl-search-box-by-type
      class="gl-mb-5"
      debounce="500"
      :placeholder="__('Search by name')"
      :is-loading="isLoadingMore"
      :value="searchTerm"
      @input="onGroupSearch"
    />

    <gl-loading-icon v-if="isLoadingInitial" size="md" />
    <div v-else-if="groups.length === 0" class="gl-text-center">
      <h5>{{ s__('Integrations|No available namespaces.') }}</h5>
      <p class="gl-mt-5">
        {{ s__('Integrations|You must have owner or maintainer permissions to link namespaces.') }}
      </p>
    </div>
    <ul
      v-else
      class="gl-list-style-none gl-pl-0 gl-border-t-1 gl-border-t-solid gl-border-t-gray-100"
      :class="{ 'gl-opacity-5': isLoadingMore }"
      data-testid="groups-list"
    >
      <groups-list-item
        v-for="group in groups"
        :key="group.id"
        :group="group"
        :disabled="isLoadingMore"
        @error="errorMessage = $event"
      />
    </ul>

    <div class="gl-display-flex gl-justify-content-center gl-mt-5">
      <gl-pagination
        v-if="showPagination"
        v-model="page"
        class="gl-mb-0"
        :per-page="$options.DEFAULT_GROUPS_PER_PAGE"
        :total-items="totalItems"
        @input="loadGroups"
      />
    </div>
  </div>
</template>
