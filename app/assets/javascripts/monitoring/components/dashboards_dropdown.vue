<script>
import { mapState, mapGetters } from 'vuex';
import {
  GlIcon,
  GlDeprecatedDropdown,
  GlDeprecatedDropdownItem,
  GlDeprecatedDropdownHeader,
  GlDeprecatedDropdownDivider,
  GlSearchBoxByType,
  GlModalDirective,
} from '@gitlab/ui';

const events = {
  selectDashboard: 'selectDashboard',
};

export default {
  components: {
    GlIcon,
    GlDeprecatedDropdown,
    GlDeprecatedDropdownItem,
    GlDeprecatedDropdownHeader,
    GlDeprecatedDropdownDivider,
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
  <gl-deprecated-dropdown
    toggle-class="dropdown-menu-toggle"
    menu-class="monitor-dashboard-dropdown-menu"
    :text="selectedDashboardText"
  >
    <div class="d-flex flex-column overflow-hidden">
      <gl-deprecated-dropdown-header class="monitor-dashboard-dropdown-header text-center">{{
        __('Dashboard')
      }}</gl-deprecated-dropdown-header>
      <gl-deprecated-dropdown-divider />
      <gl-search-box-by-type
        ref="monitorDashboardsDropdownSearch"
        v-model="searchTerm"
        class="m-2"
      />

      <div class="flex-fill overflow-auto">
        <gl-deprecated-dropdown-item
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
        </gl-deprecated-dropdown-item>

        <gl-deprecated-dropdown-divider
          v-if="starredDashboards.length && nonStarredDashboards.length"
          ref="starredListDivider"
        />

        <gl-deprecated-dropdown-item
          v-for="dashboard in nonStarredDashboards"
          :key="dashboard.path"
          :active="dashboard.path === selectedDashboardPath"
          active-class="is-active"
          @click="selectDashboard(dashboard)"
        >
          {{ dashboardDisplayName(dashboard) }}
        </gl-deprecated-dropdown-item>
      </div>

      <div
        v-show="shouldShowNoMsgContainer"
        ref="monitorDashboardsDropdownMsg"
        class="text-secondary no-matches-message"
      >
        {{ __('No matching results') }}
      </div>
    </div>
  </gl-deprecated-dropdown>
</template>
