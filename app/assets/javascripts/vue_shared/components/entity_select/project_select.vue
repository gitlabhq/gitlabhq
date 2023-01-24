<script>
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Api from '~/api';
import {
  PROJECT_TOGGLE_TEXT,
  PROJECT_HEADER_TEXT,
  FETCH_PROJECTS_ERROR,
  FETCH_PROJECT_ERROR,
} from './constants';
import EntitySelector from './entity_select.vue';

export default {
  components: {
    GlAlert,
    EntitySelector,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    inputName: {
      type: String,
      required: true,
    },
    inputId: {
      type: String,
      required: true,
    },
    groupId: {
      type: String,
      required: true,
    },
    initialSelection: {
      type: String,
      required: false,
      default: null,
    },
    clearable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      errorMessage: '',
    };
  },
  methods: {
    async fetchProjects(searchString = '') {
      let projects = [];
      try {
        const { data = [] } = await Api.groupProjects(this.groupId, searchString, {
          with_shared: true,
          include_subgroups: false,
          order_by: 'similarity',
          simple: true,
        });
        projects = data.map((item) => ({
          text: item.name_with_namespace || item.name,
          value: String(item.id),
        }));
      } catch (error) {
        this.handleError({ message: FETCH_PROJECTS_ERROR, error });
      }
      return { items: projects, totalPages: 1 };
    },
    async fetchProjectName(projectId) {
      let projectName = '';
      try {
        const { data: project } = await Api.project(projectId);
        projectName = project.name_with_namespace;
      } catch (error) {
        this.handleError({ message: FETCH_PROJECT_ERROR, error });
      }
      return projectName;
    },
    handleError({ message, error }) {
      Sentry.captureException(error);
      this.errorMessage = message;
    },
    dismissError() {
      this.errorMessage = '';
    },
  },
  i18n: {
    searchForProject: PROJECT_TOGGLE_TEXT,
    selectProject: PROJECT_HEADER_TEXT,
  },
};
</script>

<template>
  <entity-selector
    :label="label"
    :input-name="inputName"
    :input-id="inputId"
    :initial-selection="initialSelection"
    :clearable="clearable"
    :header-text="$options.i18n.selectProject"
    :default-toggle-text="$options.i18n.searchForProject"
    :fetch-items="fetchProjects"
    :fetch-initial-selection-text="fetchProjectName"
  >
    <template #error>
      <gl-alert v-if="errorMessage" class="gl-mb-3" variant="danger" @dismiss="dismissError">{{
        errorMessage
      }}</gl-alert>
    </template>
  </entity-selector>
</template>
