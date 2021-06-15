<script>
import {
  GlEmptyState,
  GlButton,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlTable,
  GlFormInput,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlTooltipDirective,
  GlPagination,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions, mapState } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
import AccessorUtils from '~/lib/utils/accessor';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { trackErrorListViewsOptions, trackErrorStatusUpdateOptions } from '../utils';
import ErrorTrackingActions from './error_tracking_actions.vue';

export const tableDataClass = 'table-col d-flex d-md-table-cell align-items-center';

export default {
  FIRST_PAGE: 1,
  PREV_PAGE: 1,
  NEXT_PAGE: 2,
  fields: [
    {
      key: 'error',
      label: __('Error'),
      thClass: 'w-60p',
      tdClass: `${tableDataClass} px-3 rounded-top`,
    },
    {
      key: 'events',
      label: __('Events'),
      thClass: 'text-right',
      tdClass: `${tableDataClass}`,
    },
    {
      key: 'users',
      label: __('Users'),
      thClass: 'text-right',
      tdClass: `${tableDataClass}`,
    },
    {
      key: 'lastSeen',
      label: __('Last seen'),
      thClass: 'w-15p',
      tdClass: `${tableDataClass}`,
    },
    {
      key: 'status',
      label: '',
      tdClass: `${tableDataClass}`,
    },
  ],
  statusFilters: {
    unresolved: __('Unresolved'),
    ignored: __('Ignored'),
    resolved: __('Resolved'),
  },
  sortFields: {
    last_seen: __('Last Seen'),
    first_seen: __('First Seen'),
    frequency: __('Frequency'),
  },
  components: {
    GlEmptyState,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlTable,
    GlFormInput,
    GlPagination,
    TimeAgo,
    ErrorTrackingActions,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    indexPath: {
      type: String,
      required: true,
    },
    enableErrorTrackingLink: {
      type: String,
      required: true,
    },
    errorTrackingEnabled: {
      type: Boolean,
      required: true,
    },
    illustrationPath: {
      type: String,
      required: true,
    },
    userCanEnableErrorTracking: {
      type: Boolean,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    listPath: {
      type: String,
      required: true,
    },
  },
  hasLocalStorage: AccessorUtils.isLocalStorageAccessSafe(),
  data() {
    return {
      errorSearchQuery: '',
      pageValue: this.$options.FIRST_PAGE,
    };
  },
  computed: {
    ...mapState('list', [
      'errors',
      'loading',
      'searchQuery',
      'sortField',
      'recentSearches',
      'pagination',
      'statusFilter',
      'cursor',
    ]),
    paginationRequired() {
      return !isEmpty(this.pagination);
    },
    errorTrackingHelpUrl() {
      return helpPagePath('operations/error_tracking');
    },
  },
  watch: {
    pagination() {
      if (typeof this.pagination.previous === 'undefined') {
        this.pageValue = this.$options.FIRST_PAGE;
      }
    },
  },
  created() {
    if (this.errorTrackingEnabled) {
      this.setEndpoint(this.indexPath);
      this.startPolling();
    }
  },
  mounted() {
    this.trackPageViews();
  },
  methods: {
    ...mapActions('list', [
      'startPolling',
      'restartPolling',
      'setEndpoint',
      'searchByQuery',
      'sortByField',
      'addRecentSearch',
      'clearRecentSearches',
      'loadRecentSearches',
      'setIndexPath',
      'fetchPaginatedResults',
      'updateStatus',
      'removeIgnoredResolvedErrors',
      'filterByStatus',
    ]),
    setSearchText(text) {
      this.errorSearchQuery = text;
      this.searchByQuery(text);
    },
    getDetailsLink(errorId) {
      return `error_tracking/${errorId}/details`;
    },
    goToNextPage() {
      this.pageValue = this.$options.NEXT_PAGE;
      this.fetchPaginatedResults(this.pagination.next.cursor);
    },
    goToPrevPage() {
      this.fetchPaginatedResults(this.pagination.previous.cursor);
    },
    goToPage(page) {
      window.scrollTo(0, 0);
      return page === this.$options.PREV_PAGE ? this.goToPrevPage() : this.goToNextPage();
    },
    isCurrentSortField(field) {
      return field === this.sortField;
    },
    isCurrentStatusFilter(filter) {
      return filter === this.statusFilter;
    },
    getIssueUpdatePath(errorId) {
      return `/${this.projectPath}/-/error_tracking/${errorId}.json`;
    },
    filterErrors(status, label) {
      this.filterValue = label;
      return this.filterByStatus(status);
    },
    updateErrosStatus({ errorId, status }) {
      // eslint-disable-next-line promise/catch-or-return
      this.updateStatus({
        endpoint: this.getIssueUpdatePath(errorId),
        status,
      }).then(() => {
        this.trackStatusUpdate(status);
      });

      this.removeIgnoredResolvedErrors(errorId);
    },
    trackPageViews() {
      const { category, action } = trackErrorListViewsOptions;
      Tracking.event(category, action);
    },
    trackStatusUpdate(status) {
      const { category, action } = trackErrorStatusUpdateOptions(status);
      Tracking.event(category, action);
    },
  },
};
</script>

<template>
  <div class="error-list">
    <div v-if="errorTrackingEnabled">
      <div
        class="row flex-column flex-md-row align-items-md-center m-0 mt-sm-2 p-3 p-sm-3 bg-secondary border"
      >
        <div class="search-box flex-fill mb-1 mb-md-0">
          <div class="filtered-search-box mb-0">
            <gl-dropdown
              :text="__('Recent searches')"
              class="filtered-search-history-dropdown-wrapper"
              toggle-class="filtered-search-history-dropdown-toggle-button gl-shadow-none! gl-border-r-gray-200! gl-border-1! gl-rounded-0!"
              :disabled="loading"
            >
              <div v-if="!$options.hasLocalStorage" class="px-3">
                {{ __('This feature requires local storage to be enabled') }}
              </div>
              <template v-else-if="recentSearches.length > 0">
                <gl-dropdown-item
                  v-for="searchQuery in recentSearches"
                  :key="searchQuery"
                  @click="setSearchText(searchQuery)"
                  >{{ searchQuery }}
                </gl-dropdown-item>
                <gl-dropdown-divider />
                <gl-dropdown-item ref="clearRecentSearches" @click="clearRecentSearches"
                  >{{ __('Clear recent searches') }}
                </gl-dropdown-item>
              </template>
              <div v-else class="px-3">{{ __("You don't have any recent searches") }}</div>
            </gl-dropdown>
            <div class="filtered-search-input-container gl-flex-grow-1">
              <gl-form-input
                v-model="errorSearchQuery"
                class="pl-2 filtered-search"
                :disabled="loading"
                :placeholder="__('Search or filter results…')"
                autofocus
                @keyup.enter.native="searchByQuery(errorSearchQuery)"
              />
            </div>
            <div class="gl-search-box-by-type-right-icons">
              <gl-button
                v-if="errorSearchQuery.length > 0"
                v-gl-tooltip.hover
                :title="__('Clear')"
                class="clear-search text-secondary"
                name="clear"
                icon="close"
                @click="errorSearchQuery = ''"
              />
            </div>
          </div>
        </div>

        <gl-dropdown
          :text="$options.statusFilters[statusFilter]"
          class="status-dropdown mx-md-1 mb-1 mb-md-0"
          :disabled="loading"
          right
        >
          <gl-dropdown-item
            v-for="(label, status) in $options.statusFilters"
            :key="status"
            @click="filterErrors(status, label)"
          >
            <span class="d-flex">
              <gl-icon
                class="gl-new-dropdown-item-check-icon"
                :class="{ invisible: !isCurrentStatusFilter(status) }"
                name="mobile-issue-close"
              />
              {{ label }}
            </span>
          </gl-dropdown-item>
        </gl-dropdown>

        <gl-dropdown :text="$options.sortFields[sortField]" right :disabled="loading">
          <gl-dropdown-item
            v-for="(label, field) in $options.sortFields"
            :key="field"
            @click="sortByField(field)"
          >
            <span class="d-flex">
              <gl-icon
                class="gl-new-dropdown-item-check-icon"
                :class="{ invisible: !isCurrentSortField(field) }"
                name="mobile-issue-close"
              />
              {{ label }}
            </span>
          </gl-dropdown-item>
        </gl-dropdown>
      </div>

      <div v-if="loading" class="py-3">
        <gl-loading-icon size="md" />
      </div>

      <template v-else>
        <h4 class="d-block d-md-none my-3">{{ __('Open errors') }}</h4>

        <gl-table
          class="error-list-table mt-3"
          :items="errors"
          :fields="$options.fields"
          :show-empty="true"
          fixed
          stacked="md"
          tbody-tr-class="table-row mb-4"
        >
          <template #head(error)>
            <div class="d-none d-md-block">{{ __('Open errors') }}</div>
          </template>
          <template #head(events)="data">
            <div class="text-md-right">{{ data.label }}</div>
          </template>
          <template #head(users)="data">
            <div class="text-md-right">{{ data.label }}</div>
          </template>

          <template #cell(error)="errors">
            <div class="d-flex flex-column">
              <gl-link class="d-flex mw-100 text-dark" :href="getDetailsLink(errors.item.id)">
                <strong class="text-truncate">{{ errors.item.title.trim() }}</strong>
              </gl-link>
              <span class="text-secondary text-truncate mw-100">
                {{ errors.item.culprit }}
              </span>
            </div>
          </template>
          <template #cell(events)="errors">
            <div class="text-right">{{ errors.item.count }}</div>
          </template>

          <template #cell(users)="errors">
            <div class="text-right">{{ errors.item.userCount }}</div>
          </template>

          <template #cell(lastSeen)="errors">
            <div class="text-lg-left text-right">
              <time-ago :time="errors.item.lastSeen" class="text-secondary" />
            </div>
          </template>
          <template #cell(status)="errors">
            <error-tracking-actions :error="errors.item" @update-issue-status="updateErrosStatus" />
          </template>
          <template #empty>
            {{ __('No errors to display.') }}
            <gl-link class="js-try-again" @click="restartPolling">
              {{ __('Check again') }}
            </gl-link>
          </template>
        </gl-table>
        <gl-pagination
          v-show="!loading"
          v-if="paginationRequired"
          :prev-page="$options.PREV_PAGE"
          :next-page="$options.NEXT_PAGE"
          :value="pageValue"
          align="center"
          @input="goToPage"
        />
      </template>
    </div>
    <div v-else-if="userCanEnableErrorTracking">
      <gl-empty-state
        :title="__('Get started with error tracking')"
        :description="__('Monitor your errors by integrating with Sentry.')"
        :primary-button-text="__('Enable error tracking')"
        :primary-button-link="enableErrorTrackingLink"
        :svg-path="illustrationPath"
      />
    </div>
    <div v-else>
      <gl-empty-state :title="__('Get started with error tracking')" :svg-path="illustrationPath">
        <template #description>
          <div>
            <span>{{ __('Monitor your errors by integrating with Sentry.') }}</span>
            <gl-link target="_blank" :href="errorTrackingHelpUrl">{{
              __('More information')
            }}</gl-link>
          </div>
        </template>
      </gl-empty-state>
    </div>
  </div>
</template>
