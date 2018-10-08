<script>
import { mapActions, mapState } from 'vuex';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import SecurityDashboardTableRow from './security_dashboard_table_row.vue';

export default {
  name: 'SecurityDashboardTable',
  components: {
    Pagination,
    SecurityDashboardTableRow,
  },
  computed: {
    ...mapState('vulnerabilities', ['vulnerabilities', 'pageInfo', 'isLoadingVulnerabilities']),
    showPagination() {
      return this.pageInfo && this.pageInfo.total;
    },
  },
  created() {
    this.fetchVulnerabilities();
  },
  methods: {
    ...mapActions('vulnerabilities', ['fetchVulnerabilities']),
  },
};
</script>

<template>
  <div class="ci-table">
    <div
      class="gl-responsive-table-row table-row-header vulnerabilities-row-header"
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

    <div v-if="isLoadingVulnerabilities">
      <security-dashboard-table-row
        v-for="n in 10"
        :key="n"
        :is-loading="true"
      />
    </div>

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

<style>
.vulnerabilities-row-header {
  color: #707070;
  padding-left: 0.4em;
  padding-right: 0.4em;
}
</style>
