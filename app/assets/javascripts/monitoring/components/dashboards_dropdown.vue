<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import {
  GlIcon,
  GlDropdown,
  GlDropdownItem,
  GlDropdownHeader,
  GlDropdownDivider,
  GlSearchBoxByType,
  GlModalDirective,
} from '@gitlab/ui';

const events = {
  selectDashboard: 'selectDashboard',
};

export default {
  components: {
    GlIcon,
    GlDropdown,
    GlDropdownItem,
    GlDropdownHeader,
    GlDropdownDivider,
    GlSearchBoxByType,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    defaultBranch: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    ...mapState('monitoringDashboard', ['allDashboards']),
    ...mapGetters('monitoringDashboard', ['selectedDashboard']),
    isSystemDashboard() {
      return this.selectedDashboard?.system_dashboard;
    },
    selectedDashboardText() {
      return this.selectedDashboard?.display_name;
    },
    selectedDashboardPath() {
      return this.selectedDashboard?.path;
    },

    filteredDashboards() {
      return this.allDashboards.filter(({ display_name = '' }) =>
        display_name.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );
    },
    shouldShowNoMsgContainer() {
      return this.filteredDashboards.length === 0;
    },
    starredDashboards() {
      return this.filteredDashboards.filter(({ starred }) => starred);
    },
    nonStarredDashboards() {
      return this.filteredDashboards.filter(({ starred }) => !starred);
    },
  },
  methods: {
    ...mapActions('monitoringDashboard', ['duplicateSystemDashboard']),
    dashboardDisplayName(dashboard) {
      return dashboard.display_name || dashboard.path || '';
    },
    selectDashboard(dashboard) {
      this.$emit(events.selectDashboard, dashboard);
    },
  },
};
</script>
<template>
  <gl-dropdown
    toggle-class="dropdown-menu-toggle"
    menu-class="monitor-dashboard-dropdown-menu"
    :text="selectedDashboardText"
  >
    <div class="d-flex flex-column overflow-hidden">
      <gl-dropdown-header class="monitor-dashboard-dropdown-header text-center">{{
        __('Dashboard')
      }}</gl-dropdown-header>
      <gl-dropdown-divider />
      <gl-search-box-by-type
        ref="monitorDashboardsDropdownSearch"
        v-model="searchTerm"
        class="m-2"
      />

      <div class="flex-fill overflow-auto">
        <gl-dropdown-item
          v-for="dashboard in starredDashboards"
          :key="dashboard.path"
          :active="dashboard.path === selectedDashboardPath"
          active-class="is-active"
          @click="selectDashboard(dashboard)"
        >
          <div class="d-flex">
            {{ dashboardDisplayName(dashboard) }}
            <gl-icon class="text-muted ml-auto" name="star" />
          </div>
        </gl-dropdown-item>

        <gl-dropdown-divider
          v-if="starredDashboards.length && nonStarredDashboards.length"
          ref="starredListDivider"
        />

        <gl-dropdown-item
          v-for="dashboard in nonStarredDashboards"
          :key="dashboard.path"
          :active="dashboard.path === selectedDashboardPath"
          active-class="is-active"
          @click="selectDashboard(dashboard)"
        >
          {{ dashboardDisplayName(dashboard) }}
        </gl-dropdown-item>
      </div>

      <div
        v-show="shouldShowNoMsgContainer"
        ref="monitorDashboardsDropdownMsg"
        class="text-secondary no-matches-message"
      >
        {{ __('No matching results') }}
      </div>

      <!-- 
           This Duplicate Dashboard item will be removed from the dashboards dropdown 
           in https://gitlab.com/gitlab-org/gitlab/-/issues/223223
      -->
      <template v-if="isSystemDashboard">
        <gl-dropdown-divider />

        <gl-dropdown-item v-gl-modal="modalId" data-testid="duplicateDashboardItem">
          {{ s__('Metrics|Duplicate dashboard') }}
        </gl-dropdown-item>
      </template>
    </div>
  </gl-dropdown>
</template>
