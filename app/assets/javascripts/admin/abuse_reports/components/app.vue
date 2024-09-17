<script>
import { GlPagination } from '@gitlab/ui';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import FilteredSearchBar from './abuse_reports_filtered_search_bar.vue';
import AbuseReportRow from './abuse_report_row.vue';

export default {
  name: 'AbuseReportsApp',
  components: {
    AbuseReportRow,
    FilteredSearchBar,
    EmptyResult,
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

    <empty-result v-if="abuseReports.length == 0" />
    <ul v-else class="gl-pl-0">
      <li v-for="(report, index) in abuseReports" :key="index" class="gl-list-none">
        <abuse-report-row :report="report" />
      </li>
    </ul>

    <gl-pagination
      v-if="showPagination"
      :value="pagination.currentPage"
      :per-page="pagination.perPage"
      :total-items="pagination.totalItems"
      :link-gen="paginationLinkGenerator"
      align="center"
      class="gl-mt-3"
    />
  </div>
</template>
