<script>
import {
  GlAlert,
  GlButton,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlTooltipDirective,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { __, s__, sprintf } from '~/locale';
import {
  getParameterValues,
  updateHistory,
  setUrlParams,
  removeParams,
} from '~/lib/utils/url_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  SEARCH_ALL_SUITES_THRESHOLD,
  SEARCH_SCOPE_SUITE,
  SEARCH_SCOPE_ALL,
} from '../stores/test_reports/constants';
import EmptyState from './empty_state.vue';
import TestSearchResults from './test_search_results.vue';
import TestSuiteTable from './test_suite_table.vue';
import TestSummary from './test_summary.vue';
import TestSummaryTable from './test_summary_table.vue';

export default {
  name: 'TestReports',
  components: {
    EmptyState,
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlSearchBoxByType,
    TestSearchResults,
    TestSuiteTable,
    TestSummary,
    TestSummaryTable,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState('testReports', [
      'isLoading',
      'selectedSuiteIndex',
      'testReports',
      'searchTerm',
      'searchScope',
      'hasFetchedAllSuites',
      'isLoadingAllSuites',
    ]),
    ...mapGetters('testReports', [
      'getSelectedSuite',
      'getTestSuites',
      'isSearching',
      'getTotalSuiteCount',
      'getSearchResultsCount',
    ]),
    showSuite() {
      return this.selectedSuiteIndex !== null;
    },
    showTests() {
      const { test_suites: testSuites = [] } = this.testReports;
      return testSuites.length > 0;
    },
    headingText() {
      if (this.isSearching) {
        return sprintf(s__('TestReports|Search results (%{count})'), {
          count: this.getSearchResultsCount,
        });
      }
      if (this.showSuite) {
        return this.getSelectedSuite.name || __('Suite');
      }
      return __('Summary');
    },
    showScopeHint() {
      return this.isSearching && this.showSuite;
    },
    isScopedToSuite() {
      return this.searchScope === SEARCH_SCOPE_SUITE;
    },
    currentSuiteName() {
      return this.getSelectedSuite?.name || '';
    },
    needsFetchConfirmation() {
      return (
        this.isSearching &&
        this.searchScope === SEARCH_SCOPE_ALL &&
        !this.hasFetchedAllSuites &&
        !this.isLoadingAllSuites &&
        this.getTotalSuiteCount > this.$options.searchAllSuitesThreshold
      );
    },
    searchAllDescription() {
      return sprintf(
        s__(
          'TestReports|This pipeline has %{count} jobs. Search results will include tests from all jobs.',
        ),
        { count: this.getTotalSuiteCount },
      );
    },
  },
  async created() {
    await this.fetchSummary();
    const jobName = getParameterValues('job_name')[0] || '';
    if (jobName.length > 0) {
      const indexToSelect = this.getTestSuites.findIndex((test) => test.name === jobName);

      this.setSelectedSuiteIndex(indexToSelect);
      this.setSearchScope(SEARCH_SCOPE_SUITE);
      this.fetchTestSuite(indexToSelect);
    }
  },
  methods: {
    ...mapActions('testReports', [
      'fetchTestSuite',
      'fetchSummary',
      'fetchAllSuites',
      'setSelectedSuiteIndex',
      'removeSelectedSuiteIndex',
      'setSearchTerm',
      'setSearchScope',
      'setPage',
    ]),
    onSearch(term) {
      this.setSearchTerm(term);

      if (term.trim().length === 0) {
        if (this.showSuite) {
          this.setSearchScope(SEARCH_SCOPE_SUITE);
        }
        return;
      }

      if (this.showSuite && this.searchScope !== SEARCH_SCOPE_ALL) {
        this.setSearchScope(SEARCH_SCOPE_SUITE);
        if (!this.hasFetchedAllSuites) {
          this.fetchTestSuite(this.selectedSuiteIndex);
        }
      } else {
        this.setSearchScope(SEARCH_SCOPE_ALL);
        if (
          !this.hasFetchedAllSuites &&
          this.getTotalSuiteCount <= this.$options.searchAllSuitesThreshold
        ) {
          this.fetchAllSuites();
        }
      }
    },
    expandToAllJobs() {
      this.setSearchScope(SEARCH_SCOPE_ALL);
      if (
        !this.hasFetchedAllSuites &&
        this.getTotalSuiteCount <= this.$options.searchAllSuitesThreshold
      ) {
        this.fetchAllSuites();
      }
    },
    summaryBackClick() {
      this.removeSelectedSuiteIndex();
      this.setSearchScope(SEARCH_SCOPE_ALL);
      this.setSearchTerm('');

      updateHistory({
        url: removeParams(['job_name']),
        title: document.title,
        replace: true,
      });

      this.setPage(1);
    },
    summaryTableRowClick(index) {
      this.setSelectedSuiteIndex(index);
      this.setSearchScope(SEARCH_SCOPE_SUITE);
      this.setSearchTerm('');

      this.fetchTestSuite(index);

      const urlParams = {
        job_name: this.getSelectedSuite.name,
      };

      updateHistory({
        url: setUrlParams(urlParams),
        title: document.title,
        replace: true,
      });
    },
    beforeEnterTransition() {
      document.documentElement.style.overflowX = 'hidden';
    },
    afterLeaveTransition() {
      document.documentElement.style.overflowX = '';
    },
  },
  searchDebounce: DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
  searchAllSuitesThreshold: SEARCH_ALL_SUITES_THRESHOLD,
};
</script>

<template>
  <div v-if="isLoading">
    <gl-loading-icon size="lg" class="gl-mt-3" />
  </div>

  <div v-else-if="!isLoading && showTests" data-testid="tests-detail">
    <div class="gl-mt-3 gl-flex gl-w-full gl-items-center">
      <gl-button
        v-if="showSuite && !isSearching"
        v-gl-tooltip
        size="small"
        class="js-back-button gl-mr-3"
        icon="chevron-lg-left"
        :aria-label="__('Go back')"
        :title="__('Go back')"
        @click="summaryBackClick"
      />
      <h4 class="gl-grow">{{ headingText }}</h4>
      <gl-search-box-by-type
        v-if="glFeatures.junitTestReportSearch"
        :value="searchTerm"
        :debounce="$options.searchDebounce"
        :placeholder="s__('TestReports|Filter by test name or class')"
        class="gl-min-w-37 gl-flex-shrink-0"
        data-testid="test-cases-search"
        @input="onSearch"
      />
    </div>

    <div
      v-if="showScopeHint"
      class="gl-mb-3 gl-mt-2 gl-flex gl-items-center gl-gap-3 gl-text-sm gl-text-subtle"
      data-testid="search-scope-hint"
    >
      <template v-if="isScopedToSuite">
        <span>{{
          sprintf(s__('TestReports|Showing results from %{name}'), { name: currentSuiteName })
        }}</span>
        <span>&middot;</span>
        <gl-button
          variant="link"
          size="small"
          class="!gl-text-sm"
          data-testid="search-all-jobs-link"
          @click="expandToAllJobs"
          >{{ s__('TestReports|Search all jobs') }}</gl-button
        >
      </template>
      <template v-else>
        <span>{{ s__('TestReports|Showing results from all jobs') }}</span>
      </template>
    </div>

    <div v-if="isSearching && glFeatures.junitTestReportSearch" data-testid="search-view">
      <gl-alert
        v-if="needsFetchConfirmation"
        :dismissible="false"
        :primary-button-text="s__('TestReports|Search all jobs')"
        variant="info"
        class="gl-mt-3"
        data-testid="search-all-prompt"
        @primary-action="fetchAllSuites"
      >
        {{ searchAllDescription }}
      </gl-alert>

      <test-search-results v-else />
    </div>

    <transition
      v-else
      name="slide"
      @before-enter="beforeEnterTransition"
      @after-leave="afterLeaveTransition"
    >
      <div v-if="showSuite" key="detail" class="slide-enter-to-element gl-w-full">
        <test-summary :report="getSelectedSuite" />
        <test-suite-table />
      </div>

      <div v-else key="summary" class="slide-enter-from-element gl-w-full">
        <test-summary :report="testReports" />
        <test-summary-table @row-click="summaryTableRowClick" />
      </div>
    </transition>
  </div>

  <empty-state v-else />
</template>
