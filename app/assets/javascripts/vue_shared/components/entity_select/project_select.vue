<script>
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Api from '~/api';
import SafeHtml from '~/vue_shared/directives/safe_html';
import {
  PROJECT_TOGGLE_TEXT,
  PROJECT_HEADER_TEXT,
  FETCH_PROJECTS_ERROR,
  FETCH_PROJECT_ERROR,
} from './constants';
import EntitySelector from './entity_select.vue';
import { initialSelectionPropValidator } from './utils';

export default {
  components: {
    GlAlert,
    EntitySelector,
  },
  directives: {
    SafeHtml,
  },
  props: {
    block: {
      type: Boolean,
      required: false,
      default: false,
    },
    label: {
      type: String,
      required: true,
    },
    hasHtmlLabel: {
      type: Boolean,
      required: false,
      default: false,
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
      required: false,
      default: null,
    },
    userId: {
      type: String,
      required: false,
      default: null,
    },
    withShared: {
      type: Boolean,
      required: false,
      default: true,
    },
    includeSubgroups: {
      type: Boolean,
      required: false,
      default: false,
    },
    membership: {
      type: Boolean,
      required: false,
      default: false,
    },
    orderBy: {
      type: String,
      required: false,
      default: 'similarity',
    },
    initialSelection: {
      type: [String, Number, Object],
      required: false,
      default: null,
      validator: initialSelectionPropValidator,
    },
    emptyText: {
      type: String,
      required: false,
      default: PROJECT_TOGGLE_TEXT,
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
        const { data = [] } = await (() => {
          const commonParams = {
            order_by: this.orderBy,
            simple: true,
          };

          if (this.groupId) {
            return Api.groupProjects(this.groupId, searchString, {
              ...commonParams,
              with_shared: this.withShared,
              include_subgroups: this.includeSubgroups,
              simple: true,
            });
          }
          // Note: the whole userId handling supports a single project selector that is slated for
          // removal. Once we have deleted app/views/clusters/clusters/_advanced_settings.html.haml,
          // we should be able to clean this up.
          if (this.userId) {
            return Api.userProjects(
              this.userId,
              searchString,
              {
                with_shared: this.withShared,
                include_subgroups: this.includeSubgroups,
              },
              (res) => ({ data: res }),
            );
          }
          return Api.projects(searchString, {
            ...commonParams,
            membership: this.membership,
          });
        })();
        projects = data.map((project) => this.mapProjectData(project));
      } catch (error) {
        this.handleError({ message: FETCH_PROJECTS_ERROR, error });
      }
      return { items: projects, totalPages: 1 };
    },
    async fetchInitialProject(projectId) {
      try {
        const response = await Api.project(projectId);

        return this.mapProjectData(response.data);
      } catch (error) {
        this.handleError({ message: FETCH_PROJECT_ERROR, error });

        return {};
      }
    },
    mapProjectData(project) {
      return {
        ...project,
        text: project.name_with_namespace || project.name,
        value: String(project.id),
      };
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
    :header-text="$options.i18n.selectProject"
    :default-toggle-text="emptyText"
    :fetch-items="fetchProjects"
    :fetch-initial-selection="fetchInitialProject"
    :block="block"
    clearable
    v-on="$listeners"
  >
    <template v-if="hasHtmlLabel" #label>
      <span v-safe-html="label"></span>
    </template>
    <template #error>
      <gl-alert v-if="errorMessage" class="gl-mb-3" variant="danger" @dismiss="dismissError">{{
        errorMessage
      }}</gl-alert>
    </template>
  </entity-selector>
</template>
