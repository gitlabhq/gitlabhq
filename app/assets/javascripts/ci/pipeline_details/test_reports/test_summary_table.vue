<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { __, s__, sprintf } from '~/locale';

const SORTABLE_COLUMNS = [
  { key: 'failed_count', label: __('Failed') },
  { key: 'error_count', label: __('Errors') },
  { key: 'skipped_count', label: __('Skipped') },
  { key: 'success_count', label: __('Passed') },
  { key: 'total_count', label: __('Total') },
];

export default {
  name: 'TestsSummaryTable',
  components: {
    GlButton,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  // Static constant — not reactive, accessed via $options.sortableColumns in template
  sortableColumns: SORTABLE_COLUMNS,
  props: {
    heading: {
      type: String,
      required: false,
      default: s__('TestReports|Jobs'),
    },
  },
  emits: ['row-click'],
  data() {
    return {
      sortKey: 'failed_count',
      sortDesc: true,
    };
  },
  computed: {
    ...mapGetters('testReports', ['getTestSuites']),
    hasSuites() {
      return this.getTestSuites.length > 0;
    },
    sortedTestSuites() {
      const { sortKey, sortDesc } = this;
      const suites = this.getTestSuites.map((testSuite, originalIndex) => ({
        ...testSuite,
        originalIndex,
      }));

      return suites.sort((a, b) => (sortDesc ? b[sortKey] - a[sortKey] : a[sortKey] - b[sortKey]));
    },
  },
  methods: {
    tableRowClick(index) {
      this.$emit('row-click', index);
    },
    toggleSort(key) {
      if (this.sortKey === key) {
        this.sortDesc = !this.sortDesc;
      } else {
        this.sortKey = key;
        this.sortDesc = true;
      }
    },
    sortIconFor(key) {
      if (this.sortKey !== key) {
        return null;
      }
      return this.sortDesc ? 'sort-highest' : 'sort-lowest';
    },
    sortButtonLabelFor({ key, label }) {
      if (this.sortKey !== key) {
        return sprintf(s__('TestReports|Sort by %{label}'), { label });
      }

      return this.sortDesc
        ? sprintf(s__('TestReports|%{label}, sorted descending'), { label })
        : sprintf(s__('TestReports|%{label}, sorted ascending'), { label });
    },
    ariaSortFor(key) {
      if (this.sortKey !== key) return 'none';
      return this.sortDesc ? 'descending' : 'ascending';
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-mt-5">
      <h4>{{ heading }}</h4>
    </div>

    <div v-if="hasSuites" class="js-test-suites-table">
      <div role="row" class="gl-responsive-table-row table-row-header gl-font-bold">
        <div role="rowheader" class="table-section section-25 gl-pl-5">
          {{ __('Job') }}
        </div>
        <div role="rowheader" class="table-section section-25">
          {{ __('Execution time') }}
        </div>
        <div
          v-for="column in $options.sortableColumns"
          :key="column.key"
          role="rowheader"
          class="table-section section-10"
          :class="column.key === 'total_count' ? 'gl-pr-5 gl-text-right' : 'gl-text-center'"
          :aria-sort="ariaSortFor(column.key)"
        >
          <gl-button
            category="tertiary"
            :data-testid="`sort-button-${column.key}`"
            :aria-label="sortButtonLabelFor(column)"
            @click="toggleSort(column.key)"
          >
            {{ column.label }}
            <gl-icon
              v-if="sortIconFor(column.key)"
              :data-testid="`sort-icon-${column.key}`"
              :name="sortIconFor(column.key)"
              class="vertical-align-middle"
            />
          </gl-button>
        </div>
      </div>

      <div
        v-for="testSuite in sortedTestSuites"
        :key="testSuite.originalIndex"
        role="row"
        class="gl-responsive-table-row js-suite-row gl-rounded-base"
        :class="{
          'gl-responsive-table-row-clickable gl-cursor-pointer': !testSuite.suite_error,
        }"
        @click="tableRowClick(testSuite.originalIndex)"
      >
        <div class="table-section section-25">
          <div role="rowheader" class="table-mobile-header gl-truncate gl-font-bold">
            {{ __('Suite') }}
          </div>
          <div class="table-mobile-content underline gl-truncate gl-pl-5 gl-text-default">
            <gl-icon
              v-if="testSuite.suite_error"
              ref="suiteErrorIcon"
              v-gl-tooltip
              name="error"
              :title="testSuite.suite_error"
              class="vertical-align-middle"
            />
            {{ testSuite.name }}
          </div>
        </div>

        <div class="table-section section-25">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Execution time') }}
          </div>
          <div class="table-mobile-content gl-text-left">
            {{ testSuite.formattedTime }}
          </div>
        </div>

        <div class="table-section section-10 gl-text-center">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Failed') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.failed_count }}</div>
        </div>

        <div class="table-section section-10 gl-text-center">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Errors') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.error_count }}</div>
        </div>

        <div class="table-section section-10 gl-text-center">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Skipped') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.skipped_count }}</div>
        </div>

        <div class="table-section section-10 gl-text-center">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Passed') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.success_count }}</div>
        </div>

        <div class="table-section section-10 gl-text-right @md/panel:gl-pr-5">
          <div role="rowheader" class="table-mobile-header gl-font-bold">
            {{ __('Total') }}
          </div>
          <div class="table-mobile-content">{{ testSuite.total_count }}</div>
        </div>
      </div>
    </div>

    <div v-else>
      <p class="js-no-tests-suites">{{ s__('TestReports|There are no test suites to show.') }}</p>
    </div>
  </div>
</template>
