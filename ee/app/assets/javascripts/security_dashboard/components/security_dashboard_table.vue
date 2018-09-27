<script>
import { mapGetters, mapActions } from 'vuex';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import SecurityDashboardTableRow from './security_dashboard_table_row.vue';

export default {
  name: 'SecurityDashboardTable',
  components: {
    SecurityDashboardTableRow,
    Pagination,
  },
  computed: {
    ...mapGetters(['vulnerabilities', 'pageInfo', 'isLoading']),
    showPagination() {
      return this.pageInfo && this.pageInfo.total;
    },
  },
  created() {
    this.fetchVulnerabilities();
  },
  methods: {
    ...mapActions(['fetchVulnerabilities']),
  },
};
</script>

<template>
  <div class="ci-table">
    <div
      class="gl-responsive-table-row table-row-header"
      role="row"
    >
      <div
        class="table-section section-10"
        role="rowheader"
      >
        {{ s__('Reports|Severity') }}
      </div>
      <div
        class="table-section section-60"
        role="rowheader"
      >
        {{ s__('Reports|Vulnerability') }}
      </div>
      <div
        class="table-section section-30"
        role="rowheader"
      >
        {{ s__('Reports|Confidence') }}
      </div>
    </div>

    <gl-loading-icon
      v-if="isLoading"
      :size="2"
    />

    <div v-else>
      <security-dashboard-table-row
        v-for="vulnerability in vulnerabilities"
        :key="vulnerability.id"
        :vulnerability="vulnerability"
      />

      <pagination
        v-if="showPagination"
        :change="fetchVulnerabilities"
        :page-info="pageInfo"
        class="justify-content-center prepend-top-default"
      />
    </div>
  </div>
</template>

