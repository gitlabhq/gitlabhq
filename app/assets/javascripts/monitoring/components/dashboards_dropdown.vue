<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import {
  GlAlert,
  GlIcon,
  GlDropdown,
  GlDropdownItem,
  GlDropdownHeader,
  GlDropdownDivider,
  GlSearchBoxByType,
  GlModal,
  GlLoadingIcon,
  GlModalDirective,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import DuplicateDashboardForm from './duplicate_dashboard_form.vue';

const events = {
  selectDashboard: 'selectDashboard',
};

export default {
  components: {
    GlAlert,
    GlIcon,
    GlDropdown,
    GlDropdownItem,
    GlDropdownHeader,
    GlDropdownDivider,
    GlSearchBoxByType,
    GlModal,
    GlLoadingIcon,
    DuplicateDashboardForm,
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
      alert: null,
      loading: false,
      form: {},
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

    okButtonText() {
      return this.loading ? s__('Metrics|Duplicating...') : s__('Metrics|Duplicate');
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
    ok(bvModalEvt) {
      // Prevent modal from hiding in case submit fails
      bvModalEvt.preventDefault();

      this.loading = true;
      this.alert = null;
      this.duplicateSystemDashboard(this.form)
        .then(createdDashboard => {
          this.loading = false;
          this.alert = null;

          // Trigger hide modal as submit is successful
          this.$refs.duplicateDashboardModal.hide();

          // Dashboards in the default branch become available immediately.
          // Not so in other branches, so we refresh the current dashboard
          const dashboard =
            this.form.branch === this.defaultBranch ? createdDashboard : this.selectedDashboard;
          this.$emit(events.selectDashboard, dashboard);
        })
        .catch(error => {
          this.loading = false;
          this.alert = error;
        });
    },
    hide() {
      this.alert = null;
    },
    formChange(form) {
      this.form = form;
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

      <template v-if="isSystemDashboard">
        <gl-dropdown-divider />

        <gl-modal
          ref="duplicateDashboardModal"
          modal-id="duplicateDashboardModal"
          :title="s__('Metrics|Duplicate dashboard')"
          ok-variant="success"
          @ok="ok"
          @hide="hide"
        >
          <gl-alert v-if="alert" class="mb-3" variant="danger" @dismiss="alert = null">
            {{ alert }}
          </gl-alert>
          <duplicate-dashboard-form
            :dashboard="selectedDashboard"
            :default-branch="defaultBranch"
            @change="formChange"
          />
          <template #modal-ok>
            <gl-loading-icon v-if="loading" inline color="light" />
            {{ okButtonText }}
          </template>
        </gl-modal>

        <gl-dropdown-item ref="duplicateDashboardItem" v-gl-modal="'duplicateDashboardModal'">
          {{ s__('Metrics|Duplicate dashboard') }}
        </gl-dropdown-item>
      </template>
    </div>
  </gl-dropdown>
</template>
