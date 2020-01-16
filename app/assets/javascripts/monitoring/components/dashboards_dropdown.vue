<script>
import { mapState, mapActions } from 'vuex';
import {
  GlAlert,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlModal,
  GlLoadingIcon,
  GlModalDirective,
} from '@gitlab/ui';
import DuplicateDashboardForm from './duplicate_dashboard_form.vue';

const events = {
  selectDashboard: 'selectDashboard',
};

export default {
  components: {
    GlAlert,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlModal,
    GlLoadingIcon,
    DuplicateDashboardForm,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    selectedDashboard: {
      type: Object,
      required: false,
      default: () => ({}),
    },
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
    };
  },
  computed: {
    ...mapState('monitoringDashboard', ['allDashboards']),
    isSystemDashboard() {
      return this.selectedDashboard.system_dashboard;
    },
    selectedDashboardText() {
      return this.selectedDashboard.display_name;
    },
  },
  methods: {
    ...mapActions('monitoringDashboard', ['duplicateSystemDashboard']),
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
  <gl-dropdown toggle-class="dropdown-menu-toggle" :text="selectedDashboardText">
    <gl-dropdown-item
      v-for="dashboard in allDashboards"
      :key="dashboard.path"
      :active="dashboard.path === selectedDashboard.path"
      active-class="is-active"
      @click="selectDashboard(dashboard)"
    >
      {{ dashboard.display_name || dashboard.path }}
    </gl-dropdown-item>

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
          {{ loading ? s__('Metrics|Duplicating...') : s__('Metrics|Duplicate') }}
        </template>
      </gl-modal>

      <gl-dropdown-item ref="duplicateDashboardItem" v-gl-modal="'duplicateDashboardModal'">
        {{ s__('Metrics|Duplicate dashboard') }}
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
