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
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlAlert,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, __, sprintf } from '~/locale';
import { queryToObject, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  ACTIVE_SUBTAB_QUERY_PARAM,
  ACTIVE_TAB_QUERY_PARAM_NAME,
  TAB_QUERY_PARAM_VALUES,
} from '~/members/constants';

import {
  PLACEHOLDER_USER_STATUS,
  PLACEHOLDER_USER_UNASSIGNED_STATUS_OPTIONS,
  PLACEHOLDER_USER_REASSIGNED_STATUS_OPTIONS,
  PLACEHOLDER_SORT_STATUS_DESC,
  PLACEHOLDER_SORT_STATUS_ASC,
  PLACEHOLDER_SORT_SOURCE_NAME_ASC,
  PLACEHOLDER_SORT_SOURCE_NAME_DESC,
  PLACEHOLDER_TAB_AWAITING,
  PLACEHOLDER_TAB_REASSIGNED,
} from '~/import_entities/import_groups/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  FILTERED_SEARCH_TERM,
  OPERATORS_IS,
  TOKEN_TITLE_STATUS,
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import PlaceholdersTable from './placeholders_table.vue';
import CsvUploadModal from './csv_upload_modal.vue';
import KeepAllAsPlaceholderModal from './keep_all_as_placeholder_modal.vue';

const UPLOAD_CSV_PLACEHOLDERS_MODAL_ID = 'upload-placeholders-csv-modal';
const KEEP_ALL_AS_PLACEHOLDER_MODAL_ID = 'keep-all-as-placeholder-modal';

export default {
  name: 'PlaceholdersTabApp',
  components: {
    GlBadge,
    GlTab,
    GlTabs,
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlAlert,
    GlLink,
    GlSprintf,
    FilteredSearchBar,
    PlaceholdersTable,
    CsvUploadModal,
    KeepAllAsPlaceholderModal,
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
      skipResettingFilterParams: false,
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
        [ACTIVE_SUBTAB_QUERY_PARAM]:
          this.selectedTabIndex === 0 ? PLACEHOLDER_TAB_AWAITING : PLACEHOLDER_TAB_REASSIGNED,
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
    initialSortBy() {
      return this.sort || PLACEHOLDER_SORT_SOURCE_NAME_ASC;
    },
  },
  watch: {
    selectedTabIndex() {
      if (this.skipResettingFilterParams) {
        this.skipResettingFilterParams = false;
        return;
      }
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
    this.setInitialFilterAndSort();
  },
  mounted() {
    this.unassignedCount = this.pagination.awaitingReassignmentItems;
    this.reassignedCount = this.pagination.reassignedItems;
  },
  methods: {
    setInitialFilterAndSort() {
      const { sort, subtab, ...queryParams } = convertObjectPropsToCamelCase(
        queryToObject(window.location.search.substring(1), { gatherArrays: true }),
        {
          dropKeys: ['scope', 'utf8', 'tab'], // These keys are unsupported/unnecessary
        },
      );

      this.filterParams = { ...queryParams };

      if (sort) {
        this.sort = sort || PLACEHOLDER_SORT_SOURCE_NAME_ASC;
      }

      const reassignedStatuses = PLACEHOLDER_USER_REASSIGNED_STATUS_OPTIONS.map(
        (status) => status.value,
      );

      if (
        (queryParams.status && reassignedStatuses.includes(queryParams.status)) ||
        subtab === PLACEHOLDER_TAB_REASSIGNED
      ) {
        // When status param is one of the reassigned statuses, or subtab param is 'reassigned', open the reassigned tab
        this.skipResettingFilterParams = true;
        this.selectedTabIndex = 1;
      }
    },
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
      this.updateTabCount({ item, placeholderCount: 1 });
    },
    onConfirmKeepAllAsPlaceholders(placeholderCount) {
      this.updateTabCount({ placeholderCount });
    },
    updateTabCount({ item, placeholderCount }) {
      const message = item
        ? sprintf(
            s__('UserMapping|Placeholder %{name} (@%{username}) was kept as a placeholder.'),
            {
              name: item.placeholderUser.name,
              username: item.placeholderUser.username,
            },
          )
        : sprintf(s__('UserMapping|%{count} placeholder users were kept as placeholders.'), {
            count: placeholderCount,
          });

      this.$toast.show(message);
      this.reassignedCount += placeholderCount;
      this.unassignedCount -= placeholderCount;
    },
    onSort(sort) {
      this.sort = sort;
    },
  },
  helpUrl: helpPagePath('user/project/import/_index', {
    anchor: 'security-considerations',
  }),
  uploadCsvModalId: UPLOAD_CSV_PLACEHOLDERS_MODAL_ID,
  keepAllAsPlaceholderModalId: KEEP_ALL_AS_PLACEHOLDER_MODAL_ID,
  PLACEHOLDER_USER_REASSIGNED_STATUS_OPTIONS,
};
</script>

<template>
  <div>
    <gl-alert variant="warning" :dismissible="false" class="mt-3">
      <gl-sprintf
        :message="
          s__(
            'UserMapping|Contribution and membership reassignment cannot be undone. Incorrect reassignment %{linkStart}poses a security risk%{linkEnd}, so check carefully before you reassign.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="$options.helpUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
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
          :initial-sort-by="initialSortBy"
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
          :initial-sort-by="initialSortBy"
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
        <div class="gl-ml-auto gl-flex gl-gap-2">
          <template v-if="isCsvReassignmentEnabled">
            <gl-button
              v-gl-modal="$options.uploadCsvModalId"
              variant="link"
              icon="media"
              data-testid="reassign-csv-button"
            >
              {{ s__('UserMapping|Reassign with CSV file') }}
            </gl-button>
            <csv-upload-modal :modal-id="$options.uploadCsvModalId" />
          </template>
          <gl-disclosure-dropdown
            icon="ellipsis_v"
            placement="bottom-end"
            category="tertiary"
            no-caret
            block
            :auto-close="false"
          >
            <gl-disclosure-dropdown-item
              v-gl-modal="$options.keepAllAsPlaceholderModalId"
              data-testid="keep-all-as-placeholder-button"
            >
              <template #list-item>
                {{ s__('UserMapping|Keep all as placeholders') }}
              </template>
            </gl-disclosure-dropdown-item>
          </gl-disclosure-dropdown>
          <keep-all-as-placeholder-modal
            :modal-id="$options.keepAllAsPlaceholderModalId"
            :group-id="group.id"
            @confirm="onConfirmKeepAllAsPlaceholders"
          />
        </div>
      </template>
    </gl-tabs>
  </div>
</template>
