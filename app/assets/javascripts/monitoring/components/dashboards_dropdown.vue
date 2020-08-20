<script>
import { mapState, mapGetters } from 'vuex';
import {
  GlIcon,
  GlNewDropdown,
  GlNewDropdownItem,
  GlNewDropdownHeader,
  GlNewDropdownDivider,
  GlSearchBoxByType,
  GlModalDirective,
} from '@gitlab/ui';

const events = {
  selectDashboard: 'selectDashboard',
};

export default {
  components: {
    GlIcon,
    GlNewDropdown,
    GlNewDropdownItem,
    GlNewDropdownHeader,
    GlNewDropdownDivider,
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
  <gl-new-dropdown
    toggle-class="dropdown-menu-toggle"
    menu-class="monitor-dashboard-dropdown-menu"
    :text="selectedDashboardText"
  >
    <div class="d-flex flex-column overflow-hidden">
      <gl-new-dropdown-header>{{ __('Dashboard') }}</gl-new-dropdown-header>
      <gl-search-box-by-type
        ref="monitorDashboardsDropdownSearch"
        v-model="searchTerm"
        class="m-2"
      />

      <div class="flex-fill overflow-auto">
        <gl-new-dropdown-item
          v-for="dashboard in starredDashboards"
          :key="dashboard.path"
          :is-check-item="true"
          :is-checked="dashboard.path === selectedDashboardPath"
          @click="selectDashboard(dashboard)"
        >
          <div class="gl-display-flex">
            <div class="gl-flex-grow-1 gl-min-w-0">
              <div class="gl-word-break-all">
                {{ dashboardDisplayName(dashboard) }}
              </div>
            </div>
            <gl-icon class="text-muted gl-flex-shrink-0" name="star" />
          </div>
        </gl-new-dropdown-item>
        <gl-new-dropdown-divider
          v-if="starredDashboards.length && nonStarredDashboards.length"
          ref="starredListDivider"
        />

        <gl-new-dropdown-item
          v-for="dashboard in nonStarredDashboards"
          :key="dashboard.path"
          :is-check-item="true"
          :is-checked="dashboard.path === selectedDashboardPath"
          @click="selectDashboard(dashboard)"
        >
          {{ dashboardDisplayName(dashboard) }}
        </gl-new-dropdown-item>
      </div>

      <div
        v-show="shouldShowNoMsgContainer"
        ref="monitorDashboardsDropdownMsg"
        class="text-secondary no-matches-message"
      >
        {{ __('No matching results') }}
      </div>
    </div>
  </gl-new-dropdown>
</template>
