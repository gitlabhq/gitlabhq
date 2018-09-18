<script>
import Tabs from '~/vue_shared/components/tabs/tabs';
import Tab from '~/vue_shared/components/tabs/tab.vue';
import SecurityDashboardTable from './security_dashboard_table.vue';

export default {
  name: 'SecurityDashboardApp',
  components: {
    Tabs,
    Tab,
    SecurityDashboardTable,
  },
  computed: {
    count() {
      // TODO: Get the count from the overview API
      return {
        sast: null,
      };
    },
    showSastCount() {
      return this.count && this.count.sast;
    },
  },
};
</script>

<template>
  <div>
    <tabs stop-propagation>
      <tab active>
        <template slot="title">
          {{ __('SAST') }}
          <span
            v-if="showSastCount"
            class="badge badge-pill">
            {{ count.sast }}
          </span>
        </template>

        <security-dashboard-table/>
      </tab>
    </tabs>
  </div>
</template>

