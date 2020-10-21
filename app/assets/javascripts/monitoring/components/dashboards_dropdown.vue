<script>
import { mapState, mapGetters } from 'vuex';
import {
  GlIcon,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
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
    GlDropdownSectionHeader,
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
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    ...mapState('monitoringDashboard', ['allDashboards']),
    ...mapGetters('monitoringDashboard', ['selectedDashboard']),
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
      <gl-dropdown-section-header>{{ __('Dashboard') }}</gl-dropdown-section-header>
      <gl-search-box-by-type ref="monitorDashboardsDropdownSearch" v-model="searchTerm" />

      <div class="flex-fill overflow-auto">
        <gl-dropdown-item
          v-for="dashboard in starredDashboards"
          :key="dashboard.path"
          :is-check-item="true"
          :is-checked="dashboard.path === selectedDashboardPath"
          @click="selectDashboard(dashboard)"
        >
          <div class="gl-display-flex">
            <span class="gl-flex-grow-1 gl-min-w-0 gl-overflow-hidden gl-overflow-wrap-break">
              {{ dashboardDisplayName(dashboard) }}
            </span>
            <gl-icon class="text-muted gl-flex-shrink-0 gl-ml-3 gl-align-self-center" name="star" />
          </div>
        </gl-dropdown-item>
        <gl-dropdown-divider
          v-if="starredDashboards.length && nonStarredDashboards.length"
          ref="starredListDivider"
        />

        <gl-dropdown-item
          v-for="dashboard in nonStarredDashboards"
          :key="dashboard.path"
          :is-check-item="true"
          :is-checked="dashboard.path === selectedDashboardPath"
          @click="selectDashboard(dashboard)"
        >
          <span class="gl-overflow-hidden gl-overflow-wrap-break">
            {{ dashboardDisplayName(dashboard) }}
          </span>
        </gl-dropdown-item>
      </div>

      <div
        v-show="shouldShowNoMsgContainer"
        ref="monitorDashboardsDropdownMsg"
        class="text-secondary no-matches-message"
      >
        {{ __('No matching results') }}
      </div>
    </div>
  </gl-dropdown>
</template>
