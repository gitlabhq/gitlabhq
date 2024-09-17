<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import {
  GlBadge,
  GlTab,
  GlTabs,
  GlButton,
  GlModalDirective,
  GlFilteredSearchToken,
} from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, __, sprintf } from '~/locale';
import { queryToObject, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { ACTIVE_TAB_QUERY_PARAM_NAME, TAB_QUERY_PARAM_VALUES } from '~/members/constants';

import {
  PLACEHOLDER_USER_STATUS,
  PLACEHOLDER_USER_UNASSIGNED_STATUS_OPTIONS,
  PLACEHOLDER_USER_REASSIGNED_STATUS_OPTIONS,
  PLACEHOLDER_SORT_STATUS_DESC,
  PLACEHOLDER_SORT_STATUS_ASC,
  PLACEHOLDER_SORT_SOURCE_NAME_ASC,
  PLACEHOLDER_SORT_SOURCE_NAME_DESC,
} from '~/import_entities/import_groups/constants';

import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  FILTERED_SEARCH_TERM,
  OPERATORS_IS,
  TOKEN_TITLE_STATUS,
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import PlaceholdersTable from './placeholders_table.vue';
import CsvUploadModal from './csv_upload_modal.vue';

const UPLOAD_CSV_PLACEHOLDERS_MODAL_ID = 'upload-placeholders-csv-modal';

export default {
  name: 'PlaceholdersTabApp',
  components: {
    GlBadge,
    GlTab,
    GlTabs,
    GlButton,
    FilteredSearchBar,
    PlaceholdersTable,
    CsvUploadModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['group'],
  data() {
    return {
      selectedTabIndex: 0,
      unassignedCount: null,
      reassignedCount: null,
      filterParams: {},
      sort: null,
    };
  },
  computed: {
    ...mapState('placeholder', ['pagination']),
    initialFilterValue() {
      const { status, search } = this.filterParams || {};
      const filteredSearchValue = [];

      if (status) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_STATUS,
          value: {
            data: status,
          },
        });
      }

      if (search) {
        filteredSearchValue.push({
          type: FILTERED_SEARCH_TERM,
          value: {
            data: search,
          },
        });
      }

      return filteredSearchValue;
    },
    urlParams() {
      return {
        [ACTIVE_TAB_QUERY_PARAM_NAME]: TAB_QUERY_PARAM_VALUES.placeholder,
        status: this.filterParams.status,
        search: this.filterParams.search,
        sort: this.sort,
      };
    },
    unassignedUserStatuses() {
      if (this.filterParams.status) {
        return [this.filterParams.status.toUpperCase()];
      }

      return PLACEHOLDER_USER_STATUS.UNASSIGNED;
    },
    reassignedUserStatuses() {
      if (this.filterParams.status) {
        return [this.filterParams.status.toUpperCase()];
      }

      return PLACEHOLDER_USER_STATUS.REASSIGNED;
    },
    isCsvReassignmentEnabled() {
      return this.glFeatures.importerUserMappingReassignmentCsv;
    },
    sortOptions() {
      return [
        {
          id: 1,
          title: __('Status'),
          sortDirection: {
            descending: PLACEHOLDER_SORT_STATUS_DESC,
            ascending: PLACEHOLDER_SORT_STATUS_ASC,
          },
        },
        {
          id: 2,
          title: s__('UserMapping|Source name'),
          sortDirection: {
            descending: PLACEHOLDER_SORT_SOURCE_NAME_DESC,
            ascending: PLACEHOLDER_SORT_SOURCE_NAME_ASC,
          },
        },
      ];
    },
  },
  watch: {
    selectedTabIndex() {
      this.filterParams = {};
    },
    urlParams: {
      deep: true,
      handler(params) {
        if (Object.keys(params).length) {
          updateHistory({
            url: setUrlParams(params, window.location.href, true, false, true),
            title: document.title,
            replace: true,
          });
        }
      },
    },
  },
  created() {
    const { sort, ...queryParams } = convertObjectPropsToCamelCase(
      queryToObject(window.location.search.substring(1), { gatherArrays: true }),
      {
        dropKeys: ['scope', 'utf8', 'tab'], // These keys are unsupported/unnecessary
      },
    );

    this.filterParams = { ...queryParams };

    if (sort) {
      this.sort = sort;
    }
  },
  mounted() {
    this.unassignedCount = this.pagination.awaitingReassignmentItems;
    this.reassignedCount = this.pagination.reassignedItems;
  },
  methods: {
    filteredSearchTokens(options = PLACEHOLDER_USER_UNASSIGNED_STATUS_OPTIONS) {
      return [
        {
          type: TOKEN_TYPE_STATUS,
          icon: 'status',
          title: TOKEN_TITLE_STATUS,
          unique: true,
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          options,
        },
      ];
    },
    onFilter(filters = []) {
      const filterParams = {};
      const plainText = [];

      filters.forEach((filter) => {
        if (!filter.value.data) return;

        switch (filter.type) {
          case TOKEN_TYPE_STATUS:
            filterParams.status = filter.value.data;
            break;
          case FILTERED_SEARCH_TERM:
            plainText.push(filter.value.data);
            break;
          default:
            break;
        }
      });

      if (plainText.length) {
        filterParams.search = plainText.join(' ');
      }

      this.filterParams = { ...filterParams };
    },
    onConfirm(item) {
      this.$toast.show(
        sprintf(s__('UserMapping|Placeholder %{name} (@%{username}) kept as placeholder.'), {
          name: item.placeholderUser.name,
          username: item.placeholderUser.username,
        }),
      );
      this.reassignedCount += 1;
      this.unassignedCount -= 1;
    },
    onSort(sort) {
      this.sort = sort;
    },
  },
  uploadCsvModalId: UPLOAD_CSV_PLACEHOLDERS_MODAL_ID,
  initialSortBy: PLACEHOLDER_SORT_SOURCE_NAME_ASC,
  PLACEHOLDER_USER_REASSIGNED_STATUS_OPTIONS,
};
</script>

<template>
  <div>
    <gl-tabs
      v-model="selectedTabIndex"
      nav-class="gl-grow gl-items-center gl-mt-3"
      content-class="gl-pt-0"
    >
      <gl-tab>
        <template #title>
          <span>{{ s__('UserMapping|Awaiting reassignment') }}</span>
          <gl-badge class="gl-tab-counter-badge">{{ unassignedCount || 0 }}</gl-badge>
        </template>

        <filtered-search-bar
          key="filter-unassigned"
          :namespace="group.path"
          :initial-filter-value="initialFilterValue"
          :initial-sort-by="$options.initialSortBy"
          :tokens="filteredSearchTokens()"
          :sort-options="sortOptions"
          :search-input-placeholder="s__('UserMapping|Search placeholder users')"
          terms-as-tokens
          sync-filter-and-sort
          class="row-content-block gl-grow gl-border-t-0 sm:gl-flex"
          @onFilter="onFilter"
          @onSort="onSort"
        />
        <placeholders-table
          key="unassigned"
          data-testid="placeholders-table-unassigned"
          :query-statuses="unassignedUserStatuses"
          :query-search="filterParams.search"
          :query-sort="sort"
          @confirm="onConfirm"
        />
      </gl-tab>

      <gl-tab>
        <template #title>
          <span>{{ s__('UserMapping|Reassigned') }}</span>
          <gl-badge class="gl-tab-counter-badge">{{ reassignedCount || 0 }}</gl-badge>
        </template>

        <filtered-search-bar
          key="filter-reassigned"
          :namespace="group.path"
          :initial-filter-value="initialFilterValue"
          :initial-sort-by="$options.initialSortBy"
          :tokens="filteredSearchTokens($options.PLACEHOLDER_USER_REASSIGNED_STATUS_OPTIONS)"
          :sort-options="sortOptions"
          :search-input-placeholder="s__('UserMapping|Search placeholder users')"
          terms-as-tokens
          sync-filter-and-sort
          class="row-content-block gl-grow gl-border-t-0 sm:gl-flex"
          @onFilter="onFilter"
          @onSort="onSort"
        />
        <placeholders-table
          key="reassigned"
          data-testid="placeholders-table-reassigned"
          :query-statuses="reassignedUserStatuses"
          :query-search="filterParams.search"
          :query-sort="sort"
          reassigned
        />
      </gl-tab>

      <template #tabs-end>
        <div v-if="isCsvReassignmentEnabled" class="gl-ml-auto">
          <gl-button
            v-gl-modal="$options.uploadCsvModalId"
            variant="link"
            icon="media"
            data-testid="reassign-csv-button"
          >
            {{ s__('UserMapping|Reassign with CSV file') }}
          </gl-button>
          <csv-upload-modal :modal-id="$options.uploadCsvModalId" />
        </div>
      </template>
    </gl-tabs>
  </div>
</template>
