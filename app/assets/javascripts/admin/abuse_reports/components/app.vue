<script>
import { GlEmptyState, GlPagination } from '@gitlab/ui';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import FilteredSearchBar from './abuse_reports_filtered_search_bar.vue';
import AbuseReportRow from './abuse_report_row.vue';

export default {
  name: 'AbuseReportsApp',
  components: {
    AbuseReportRow,
    FilteredSearchBar,
    GlEmptyState,
    GlPagination,
  },
  props: {
    abuseReports: {
      type: Array,
      required: true,
    },
    pagination: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showPagination() {
      return this.pagination.totalItems > this.pagination.perPage;
    },
  },
  methods: {
    paginationLinkGenerator(page) {
      return mergeUrlParams({ page }, window.location.href);
    },
  },
};
</script>
<template>
  <div>
    <filtered-search-bar />

    <gl-empty-state v-if="abuseReports.length == 0" :title="s__('AbuseReports|No reports found')" />
    <ul v-else class="gl-pl-0">
      <li v-for="(report, index) in abuseReports" :key="index" class="gl-list-style-none">
        <abuse-report-row :report="report" />
      </li>
    </ul>

    <gl-pagination
      v-if="showPagination"
      :value="pagination.currentPage"
      :per-page="pagination.perPage"
      :total-items="pagination.totalItems"
      :link-gen="paginationLinkGenerator"
      :prev-text="__('Prev')"
      :next-text="__('Next')"
      :label-next-page="__('Go to next page')"
      :label-prev-page="__('Go to previous page')"
      align="center"
      class="gl-mt-3"
    />
  </div>
</template>
