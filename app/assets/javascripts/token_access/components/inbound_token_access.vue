<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlFormInput,
  GlLink,
  GlIcon,
  GlLoadingIcon,
  GlSprintf,
  GlToggle,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import inboundAddProjectCIJobTokenScopeMutation from '../graphql/mutations/inbound_add_project_ci_job_token_scope.mutation.graphql';
import inboundRemoveProjectCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_project_ci_job_token_scope.mutation.graphql';
import inboundUpdateCIJobTokenScopeMutation from '../graphql/mutations/inbound_update_ci_job_token_scope.mutation.graphql';
import inboundGetCIJobTokenScopeQuery from '../graphql/queries/inbound_get_ci_job_token_scope.query.graphql';
import inboundGetProjectsWithCIJobTokenScopeQuery from '../graphql/queries/inbound_get_projects_with_ci_job_token_scope.query.graphql';
import TokenProjectsTable from './token_projects_table.vue';

export default {
  i18n: {
    toggleLabelTitle: s__('CICD|Limit access %{italicStart}to%{italicEnd} this project'),
    toggleHelpText: s__(
      `CICD|Prevent access to this project from other project CI/CD job tokens, unless the other project is added to the allowlist. It is a security risk to disable this feature, because unauthorized projects might attempt to retrieve an active token and access the API. %{linkStart}Learn more.%{linkEnd}`,
    ),
    cardHeaderTitle: s__(
      'CICD|Allow CI job tokens from the following projects to access this project',
    ),
    settingDisabledMessage: s__(
      'CICD|Enable feature to limit job token access, so only the projects in this list can access this project with a CI/CD job token.',
    ),
    addProject: __('Add project'),
    cancel: __('Cancel'),
    addProjectPlaceholder: __('Paste project path (i.e. gitlab-org/gitlab)'),
    projectsFetchError: __('There was a problem fetching the projects'),
    scopeFetchError: __('There was a problem fetching the job token scope value'),
  },
  fields: [
    {
      key: 'project',
      label: __('Project with access'),
      thClass: 'gl-border-t-none!',
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-text-right',
      thClass: 'gl-border-t-none!',
    },
  ],
  components: {
    GlAlert,
    GlButton,
    GlCard,
    GlFormInput,
    GlLink,
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
    GlToggle,
    TokenProjectsTable,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  apollo: {
    inboundJobTokenScopeEnabled: {
      query: inboundGetCIJobTokenScopeQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ project }) {
        return project.ciCdSettings.inboundJobTokenScopeEnabled;
      },
      error() {
        createAlert({ message: this.$options.i18n.scopeFetchError });
      },
    },
    projects: {
      query: inboundGetProjectsWithCIJobTokenScopeQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ project }) {
        return project?.ciJobTokenScope?.inboundAllowlist?.nodes ?? [];
      },
      error() {
        createAlert({ message: this.$options.i18n.projectsFetchError });
      },
    },
  },
  data() {
    return {
      inboundJobTokenScopeEnabled: null,
      targetProjectPath: '',
      projects: [],
      isAddFormVisible: false,
    };
  },
  computed: {
    isProjectPathEmpty() {
      return this.targetProjectPath === '';
    },
    ciJobTokenHelpPage() {
      return helpPagePath('ci/jobs/ci_job_token#allow-access-to-your-project-with-a-job-token');
    },
  },
  methods: {
    async updateCIJobTokenScope() {
      try {
        const {
          data: {
            projectCiCdSettingsUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: inboundUpdateCIJobTokenScopeMutation,
          variables: {
            input: {
              fullPath: this.fullPath,
              inboundJobTokenScopeEnabled: this.inboundJobTokenScopeEnabled,
            },
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        this.inboundJobTokenScopeEnabled = !this.inboundJobTokenScopeEnabled;
        createAlert({ message: error.message });
      }
    },
    async addProject() {
      try {
        const {
          data: {
            ciJobTokenScopeAddProject: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: inboundAddProjectCIJobTokenScopeMutation,
          variables: {
            projectPath: this.fullPath,
            targetProjectPath: this.targetProjectPath,
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        createAlert({ message: error.message });
      } finally {
        this.clearTargetProjectPath();
        this.getProjects();
      }
    },
    async removeProject(removeTargetPath) {
      try {
        const {
          data: {
            ciJobTokenScopeRemoveProject: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: inboundRemoveProjectCIJobTokenScopeMutation,
          variables: {
            projectPath: this.fullPath,
            targetProjectPath: removeTargetPath,
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        createAlert({ message: error.message });
      } finally {
        this.getProjects();
      }
    },
    clearTargetProjectPath() {
      this.targetProjectPath = '';
      this.isAddFormVisible = false;
    },
    getProjects() {
      this.$apollo.queries.projects.refetch();
    },
    showAddForm() {
      this.isAddFormVisible = true;
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="$apollo.loading" size="lg" class="gl-mt-5" />
    <template v-else>
      <gl-toggle
        v-model="inboundJobTokenScopeEnabled"
        :label="$options.i18n.toggleLabelTitle"
        @change="updateCIJobTokenScope"
      >
        <template #label>
          <gl-sprintf :message="$options.i18n.toggleLabelTitle">
            <template #italic="{ content }">
              <i>{{ content }}</i>
            </template>
          </gl-sprintf>
        </template>
        <template #help>
          <gl-sprintf :message="$options.i18n.toggleHelpText">
            <template #link="{ content }">
              <gl-link :href="ciJobTokenHelpPage" class="inline-link" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </template>
      </gl-toggle>

      <div>
        <gl-card
          class="gl-new-card"
          header-class="gl-new-card-header"
          body-class="gl-new-card-body gl-px-0"
        >
          <template #header>
            <div class="gl-new-card-title-wrapper">
              <h5 class="gl-new-card-title">{{ $options.i18n.cardHeaderTitle }}</h5>
              <span class="gl-new-card-count">
                <gl-icon name="project" class="gl-mr-2" />
                {{ projects.length }}
              </span>
            </div>
            <div class="gl-new-card-actions">
              <gl-button
                v-if="!isAddFormVisible"
                size="small"
                data-testid="toggle-form-btn"
                @click="showAddForm"
                >{{ $options.i18n.addProject }}</gl-button
              >
            </div>
          </template>

          <div v-if="isAddFormVisible" class="gl-new-card-add-form gl-m-3">
            <h4 class="gl-mt-0">{{ $options.i18n.addProject }}</h4>
            <gl-form-input
              v-model="targetProjectPath"
              :placeholder="$options.i18n.addProjectPlaceholder"
            />
            <div class="gl-display-flex gl-mt-5">
              <gl-button
                variant="confirm"
                :disabled="isProjectPathEmpty"
                class="gl-mr-3"
                data-testid="add-project-btn"
                @click="addProject"
              >
                {{ $options.i18n.addProject }}
              </gl-button>
              <gl-button @click="clearTargetProjectPath">{{ $options.i18n.cancel }}</gl-button>
            </div>
          </div>

          <token-projects-table
            :projects="projects"
            :table-fields="$options.fields"
            @removeProject="removeProject"
          />
        </gl-card>
        <gl-alert
          v-if="!inboundJobTokenScopeEnabled"
          class="gl-mb-3"
          variant="warning"
          :dismissible="false"
          :show-icon="false"
        >
          {{ $options.i18n.settingDisabledMessage }}
        </gl-alert>
      </div>
    </template>
  </div>
</template>
