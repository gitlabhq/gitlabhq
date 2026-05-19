import { isMatch, pick } from 'lodash-es';
import { defineStore } from 'pinia';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import { getDisplayName, projectKeys, transformFrontendSettings } from '../utils';

export const useErrorTrackingSettings = defineStore('errorTrackingSettings', {
  state: () => ({
    apiHost: '',
    enabled: false,
    integrated: false,
    token: '',
    projects: [],
    isLoadingProjects: false,
    selectedProject: null,
    settingsLoading: false,
    connectSuccessful: false,
    connectError: false,
    listProjectsEndpoint: '',
    operationsSettingsEndpoint: '',
  }),

  getters: {
    hasProjects: (state) => Boolean(state.projects) && state.projects.length > 0,

    isProjectInvalid() {
      return (
        Boolean(this.selectedProject) &&
        this.hasProjects &&
        !this.projects.some((project) => isMatch(this.selectedProject, project))
      );
    },

    dropdownLabel() {
      if (this.selectedProject !== null) {
        return getDisplayName(this.selectedProject);
      }
      if (!this.hasProjects) {
        return s__('ErrorTracking|No projects available');
      }
      return s__('ErrorTracking|Select project');
    },

    invalidProjectLabel: (state) => {
      if (state.selectedProject) {
        return sprintf(
          __('Project "%{name}" is no longer available. Select another project to continue.'),
          { name: state.selectedProject.name },
        );
      }
      return '';
    },

    projectSelectionLabel: (state) => {
      if (state.token) {
        return s__(
          'ErrorTracking|Click Connect to reestablish the connection to Sentry and activate the dropdown.',
        );
      }
      return s__('ErrorTracking|To enable project selection, enter a valid Auth Token.');
    },
  },

  actions: {
    setInitialState({
      apiHost,
      enabled,
      integrated,
      project,
      token,
      listProjectsEndpoint,
      operationsSettingsEndpoint,
    }) {
      this.enabled = parseBoolean(enabled);
      this.integrated = parseBoolean(integrated);
      this.apiHost = apiHost;
      this.token = token;
      this.listProjectsEndpoint = listProjectsEndpoint;
      this.operationsSettingsEndpoint = operationsSettingsEndpoint;

      if (project) {
        this.selectedProject = pick(
          convertObjectPropsToCamelCase(JSON.parse(project)),
          projectKeys,
        );
      }
    },

    updateApiHost(apiHost) {
      this.apiHost = apiHost;
      this.connectSuccessful = false;
      this.connectError = false;
    },

    updateEnabled(enabled) {
      this.enabled = enabled;
    },

    updateIntegrated(integrated) {
      this.integrated = integrated;
    },

    updateToken(token) {
      this.token = token;
      this.connectSuccessful = false;
      this.connectError = false;
    },

    updateSelectedProject(selectedProject) {
      this.selectedProject = selectedProject;
    },

    async fetchProjects() {
      this.isLoadingProjects = true;
      this.connectSuccessful = false;
      this.connectError = false;

      try {
        const {
          data: { projects },
        } = await axios.get(this.listProjectsEndpoint, {
          params: { api_host: this.apiHost, token: this.token },
        });
        this.projects = projects
          .map(convertObjectPropsToCamelCase)
          .map((project) => pick(project, projectKeys));
        this.connectSuccessful = true;
      } catch {
        this.connectError = true;
        this.projects = [];
      } finally {
        this.isLoadingProjects = false;
      }
    },

    async updateSettings() {
      this.settingsLoading = true;

      try {
        await axios.patch(this.operationsSettingsEndpoint, {
          project: {
            error_tracking_setting_attributes: {
              ...transformFrontendSettings(this.$state),
            },
          },
        });
        // Fixes a problem that refreshCurrentPage() does nothing when a hash is set.
        // eslint-disable-next-line no-restricted-globals
        history.pushState('', document.title, window.location.pathname + window.location.search);

        refreshCurrentPage();
      } catch (err) {
        const message = err?.response?.data?.message ?? '';
        createAlert({
          message: `${__('There was an error saving your changes.')} ${message}`,
        });
        this.settingsLoading = false;
      }
    },
  },
});
