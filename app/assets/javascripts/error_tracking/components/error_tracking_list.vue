<script>
import {
  GlAlert,
  GlEmptyState,
  GlButton,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlTable,
  GlForm,
  GlFormInput,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlSprintf,
  GlTooltipDirective,
  GlPagination,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
import AccessorUtils from '~/lib/utils/accessor';
import { __ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { joinPaths } from '~/lib/utils/url_utility';
import {
  trackErrorListViewsOptions,
  trackErrorStatusUpdateOptions,
  trackErrorStatusFilterOptions,
  trackErrorSortedByField,
} from '../events_tracking';
import { I18N_ERROR_TRACKING_LIST } from '../constants';
import ErrorTrackingActions from './error_tracking_actions.vue';
import TimelineChart from './timeline_chart.vue';

const isValidErrorId = (errorId) => {
  return /^[0-9]+$/.test(errorId);
};
export const tableDataClass = 'gl-flex md:gl-table-cell gl-items-center';
export default {
  FIRST_PAGE: 1,
  PREV_PAGE: 1,
  NEXT_PAGE: 2,
  i18n: I18N_ERROR_TRACKING_LIST,
  fields: [
    {
      key: 'error',
      label: __('Error'),
      thClass: 'gl-w-8/20',
      tdClass: `${tableDataClass}`,
    },
    {
      key: 'timeline',
      label: __('Timeline'),
      thClass: 'gl-w-4/20',
      tdClass: `${tableDataClass}`,
    },
    {
      key: 'events',
      label: __('Events'),
      thClass: 'gl-w-2/20',
      thAlignRight: true,
      tdClass: `${tableDataClass} gl-text-right`,
    },
    {
      key: 'users',
      label: __('Users'),
      thClass: 'gl-w-2/20',
      thAlignRight: true,
      tdClass: `${tableDataClass} gl-text-right`,
    },
    {
      key: 'lastSeen',
      label: __('Last seen'),
      thClass: 'gl-w-2/20',
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
    last_seen: __('Last seen'),
    first_seen: __('First seen'),
    frequency: __('Frequency'),
  },
  components: {
    GlAlert,
    GlEmptyState,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlTable,
    GlForm,
    GlFormInput,
    GlSprintf,
    GlPagination,
    TimeAgo,
    ErrorTrackingActions,
    TimelineChart,
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
    integratedErrorTrackingEnabled: {
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
    showIntegratedTrackingDisabledAlert: {
      type: Boolean,
      required: false,
    },
  },
  hasLocalStorage: AccessorUtils.canUseLocalStorage(),
  data() {
    return {
      errorSearchQuery: '',
      pageValue: this.$options.FIRST_PAGE,
      isAlertDismissed: false,
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
    previousPage() {
      return this.pagination.previous ? this.$options.PREV_PAGE : null;
    },
    nextPage() {
      return this.pagination.next ? this.$options.NEXT_PAGE : null;
    },
    errorTrackingHelpUrl() {
      return helpPagePath('operations/integrated_error_tracking');
    },
    showIntegratedDisabledAlert() {
      return !this.isAlertDismissed && this.showIntegratedTrackingDisabledAlert;
    },
  },
  watch: {
    pagination() {
      if (typeof this.pagination.previous === 'undefined') {
        this.pageValue = this.$options.FIRST_PAGE;
      }
    },
  },
  epicLink: 'https://gitlab.com/gitlab-org/gitlab/-/issues/353639',
  featureFlagLink: helpPagePath('operations/error_tracking'),
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
      if (!isValidErrorId(errorId)) {
        return 'about:blank';
      }
      return joinPaths(this.listPath, errorId, 'details');
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
      if (!isValidErrorId(errorId)) {
        return 'about:blank';
      }
      return `/${this.projectPath}/-/error_tracking/${errorId}.json`;
    },
    filterErrors(status, label) {
      this.filterValue = label;
      trackErrorStatusFilterOptions(status, this.integratedErrorTrackingEnabled);
      return this.filterByStatus(status);
    },
    sortErrorsByField(field) {
      trackErrorSortedByField(field, this.integratedErrorTrackingEnabled);
      return this.sortByField(field);
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
      trackErrorListViewsOptions(this.integratedErrorTrackingEnabled);
    },
    trackStatusUpdate(status) {
      trackErrorStatusUpdateOptions(status, this.integratedErrorTrackingEnabled);
    },
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <div v-if="errorTrackingEnabled">
      <!-- Enable ET -->
      <gl-alert
        v-if="showIntegratedDisabledAlert"
        variant="danger"
        data-testid="integrated-disabled-alert"
        @dismiss="isAlertDismissed = true"
      >
        <gl-sprintf :message="$options.i18n.integratedErrorTrackingDisabledText">
          <template #epicLink="{ content }">
            <gl-link :href="$options.epicLink" target="_blank">{{ content }}</gl-link>
          </template>
          <template #flagLink="{ content }">
            <gl-link :href="$options.featureFlagLink" target="_blank">{{ content }}</gl-link>
          </template>
          <template #settingsLink="{ content }">
            <gl-link :href="enableErrorTrackingLink" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
        <div>
          <gl-button
            category="primary"
            variant="confirm"
            :href="enableErrorTrackingLink"
            class="gl-mr-auto gl-mt-3"
          >
            {{ $options.i18n.viewProjectSettingsButton }}
          </gl-button>
        </div>
      </gl-alert>

      <!-- Search / Filter Bar -->
      <div
        class="gl-m-0 gl-flex gl-flex-col gl-gap-3 gl-bg-subtle gl-p-5 md:gl-flex-row md:gl-items-center"
      >
        <div class="gl-mb-2 gl-flex gl-grow md:gl-mb-0">
          <div class="gl-border gl-mb-0 gl-flex gl-grow gl-rounded-base gl-bg-default">
            <gl-dropdown
              icon="history"
              data-testid="recent-searches-dropdown"
              text-sr-only
              category="tertiary"
              toggle-class="!gl-border-none !gl-rounded-r-none !gl-rounded-l-base"
              :text="__('Recent searches')"
              :disabled="loading"
            >
              <div v-if="!$options.hasLocalStorage" class="gl-px-5">
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
              <div v-else class="gl-px-5">{{ __("You don't have any recent searches") }}</div>
            </gl-dropdown>
            <div class="gl-border-l gl-grow">
              <gl-form @submit.prevent="searchByQuery(errorSearchQuery)">
                <gl-form-input
                  v-model="errorSearchQuery"
                  :disabled="loading"
                  class="!gl-shadow-none"
                  :placeholder="__('Search or filter results…')"
                  autofocus
                />
              </gl-form>
            </div>

            <gl-button
              v-if="errorSearchQuery.length > 0"
              v-gl-tooltip.hover
              :title="__('Clear')"
              class="clear-search !gl-text-subtle"
              category="tertiary"
              name="clear"
              icon="close"
              @click="errorSearchQuery = ''"
            />
          </div>
        </div>

        <gl-dropdown
          data-testid="status-dropdown"
          :text="$options.statusFilters[statusFilter]"
          :disabled="loading"
          right
        >
          <gl-dropdown-item
            v-for="(label, status) in $options.statusFilters"
            :key="status"
            @click="filterErrors(status, label)"
          >
            <span class="gl-flex">
              <gl-icon
                class="gl-dropdown-item-check-icon"
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
            @click="sortErrorsByField(field)"
          >
            <span class="gl-flex">
              <gl-icon
                class="gl-dropdown-item-check-icon"
                :class="{ invisible: !isCurrentSortField(field) }"
                name="mobile-issue-close"
              />
              {{ label }}
            </span>
          </gl-dropdown-item>
        </gl-dropdown>
      </div>

      <div v-if="loading" class="gl-py-5">
        <gl-loading-icon size="lg" />
      </div>

      <!-- Results Table -->
      <template v-else>
        <h4 class="gl-my-5 gl-block md:!gl-hidden">{{ __('Open errors') }}</h4>

        <gl-table
          :items="errors"
          :fields="$options.fields"
          :show-empty="true"
          fixed
          stacked="md"
          tbody-tr-class="table-row"
        >
          <!-- table head -->
          <template #head(error)>
            <div class="gl-hidden md:gl-block">{{ __('Open errors') }}</div>
          </template>
          <template #head(events)="data">
            {{ data.label }}
          </template>
          <template #head(users)="data">
            {{ data.label }}
          </template>

          <!-- table row -->
          <template #cell(error)="errors">
            <div class="gl-flex gl-flex-col">
              <gl-link
                class="gl-flex gl-max-w-full gl-text-default"
                :href="getDetailsLink(errors.item.id)"
              >
                <strong class="gl-truncate">{{ errors.item.title.trim() }}</strong>
              </gl-link>
              <span class="gl-max-w-full gl-truncate gl-text-subtle">
                {{ errors.item.culprit }}
              </span>
            </div>
          </template>

          <template #cell(timeline)="errors">
            <timeline-chart
              v-if="errors.item.frequency"
              :timeline-data="errors.item.frequency"
              :height="70"
            />
          </template>

          <template #cell(events)="errors">
            {{ errors.item.count }}
          </template>

          <template #cell(users)="errors">
            {{ errors.item.userCount }}
          </template>

          <template #cell(lastSeen)="errors">
            <time-ago :time="errors.item.lastSeen" class="gl-text-subtle" />
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
          :prev-page="previousPage"
          :next-page="nextPage"
          :value="pageValue"
          align="center"
          @input="goToPage"
        />
      </template>
    </div>
    <!-- Get Started with ET -->
    <div v-else>
      <gl-empty-state :title="__('Get started with error tracking')" :svg-path="illustrationPath">
        <template #description>
          <div>
            <span>{{ __('Monitor your errors directly in GitLab.') }}</span>
            <gl-link target="_blank" :href="errorTrackingHelpUrl">{{
              __('How do I get started?')
            }}</gl-link>
          </div>
        </template>
      </gl-empty-state>
    </div>
  </div>
</template>
