<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlBadge, GlTab, GlTabs, GlButton, GlModalDirective } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, sprintf } from '~/locale';
import { queryToObject, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { ACTIVE_TAB_QUERY_PARAM_NAME, TAB_QUERY_PARAM_VALUES } from '~/members/constants';

import {
  PLACEHOLDER_STATUS_FAILED,
  QUERY_PARAM_FAILED,
  PLACEHOLDER_USER_STATUS,
} from '~/import_entities/import_groups/constants';

import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
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
    };
  },
  computed: {
    ...mapState('placeholder', ['pagination']),
    filteredSearchTokens() {
      return [];
    },
    initialFilterValue() {
      const { search } = this.filterParams || {};
      const filteredSearchValue = [];

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
      };
    },
    unassignedUserStatuses() {
      if (this.filterParams.status === QUERY_PARAM_FAILED) {
        return [PLACEHOLDER_STATUS_FAILED];
      }

      return PLACEHOLDER_USER_STATUS.UNASSIGNED;
    },
    reassignedUserStatuses() {
      return PLACEHOLDER_USER_STATUS.REASSIGNED;
    },
    isCsvReassignmentEnabled() {
      return this.glFeatures.importerUserMappingReassignmentCsv;
    },
  },
  watch: {
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
    this.filterParams = Object.assign(
      convertObjectPropsToCamelCase(
        queryToObject(window.location.search.substring(1), { gatherArrays: true }),
        {
          dropKeys: ['scope', 'utf8', 'tab', 'sort'], // These keys are unsupported/unnecessary
        },
      ),
    );
  },
  mounted() {
    this.unassignedCount = this.pagination.awaitingReassignmentItems;
    this.reassignedCount = this.pagination.reassignedItems;
  },
  methods: {
    onFilter(filters = []) {
      const filterParams = {};
      const plainText = [];

      filters.forEach((filter) => {
        if (!filter.value.data) return;

        switch (filter.type) {
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

      this.filterParams = {
        ...filterParams,
        status: this.filterParams.status,
      };
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
  },
  uploadCsvModalId: UPLOAD_CSV_PLACEHOLDERS_MODAL_ID,
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
          :namespace="group.path"
          :initial-filter-value="initialFilterValue"
          :tokens="filteredSearchTokens"
          :search-input-placeholder="s__('UserMapping|Search placeholder users')"
          terms-as-tokens
          class="row-content-block gl-grow gl-border-t-0 sm:gl-flex"
          @onFilter="onFilter"
        />
        <placeholders-table
          key="unassigned"
          data-testid="placeholders-table-unassigned"
          :query-statuses="unassignedUserStatuses"
          :query-search="filterParams.search"
          @confirm="onConfirm"
        />
      </gl-tab>

      <gl-tab lazy>
        <template #title>
          <span>{{ s__('UserMapping|Reassigned') }}</span>
          <gl-badge class="gl-tab-counter-badge">{{ reassignedCount || 0 }}</gl-badge>
        </template>

        <filtered-search-bar
          :namespace="group.path"
          :initial-filter-value="initialFilterValue"
          :tokens="filteredSearchTokens"
          :search-input-placeholder="s__('UserMapping|Search placeholder users')"
          terms-as-tokens
          class="row-content-block gl-grow gl-border-t-0 sm:gl-flex"
          @onFilter="onFilter"
        />
        <placeholders-table
          key="reassigned"
          data-testid="placeholders-table-reassigned"
          :query-statuses="reassignedUserStatuses"
          :query-search="filterParams.search"
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
