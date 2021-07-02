<script>
import { GlButton, GlCard, GlFormGroup, GlFormInput, GlLoadingIcon, GlToggle } from '@gitlab/ui';
import createFlash from '~/flash';
import { __, s__ } from '~/locale';
import addProjectCIJobTokenScopeMutation from '../graphql/mutations/add_project_ci_job_token_scope.mutation.graphql';
import removeProjectCIJobTokenScopeMutation from '../graphql/mutations/remove_project_ci_job_token_scope.mutation.graphql';
import updateCIJobTokenScopeMutation from '../graphql/mutations/update_ci_job_token_scope.mutation.graphql';
import getCIJobTokenScopeQuery from '../graphql/queries/get_ci_job_token_scope.query.graphql';
import getProjectsWithCIJobTokenScopeQuery from '../graphql/queries/get_projects_with_ci_job_token_scope.query.graphql';
import TokenProjectsTable from './token_projects_table.vue';

export default {
  i18n: {
    toggleLabelTitle: s__('CICD|Limit CI_JOB_TOKEN access'),
    toggleHelpText: s__(
      `CICD|Manage which projects can use this project's CI_JOB_TOKEN CI/CD variable for API access`,
    ),
    cardHeaderTitle: s__('CICD|Add an existing project to the scope'),
    formGroupLabel: __('Search for project'),
    addProject: __('Add project'),
    cancel: __('Cancel'),
    addProjectPlaceholder: __('Paste project path (i.e. gitlab-org/gitlab)'),
    projectsFetchError: __('There was a problem fetching the projects'),
    scopeFetchError: __('There was a problem fetching the job token scope value'),
  },
  components: {
    GlButton,
    GlCard,
    GlFormGroup,
    GlFormInput,
    GlLoadingIcon,
    GlToggle,
    TokenProjectsTable,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  apollo: {
    jobTokenScopeEnabled: {
      query: getCIJobTokenScopeQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.project.ciCdSettings.jobTokenScopeEnabled;
      },
      error() {
        createFlash({ message: this.$options.i18n.scopeFetchError });
      },
    },
    projects: {
      query: getProjectsWithCIJobTokenScopeQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.project?.ciJobTokenScope?.projects?.nodes ?? [];
      },
      error() {
        createFlash({ message: this.$options.i18n.projectsFetchError });
      },
    },
  },
  data() {
    return {
      jobTokenScopeEnabled: null,
      targetProjectPath: '',
      projects: [],
    };
  },
  computed: {
    isProjectPathEmpty() {
      return this.targetProjectPath === '';
    },
  },
  methods: {
    async updateCIJobTokenScope() {
      try {
        const {
          data: {
            ciCdSettingsUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateCIJobTokenScopeMutation,
          variables: {
            input: {
              fullPath: this.fullPath,
              jobTokenScopeEnabled: this.jobTokenScopeEnabled,
            },
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        createFlash({ message: error });
      }
    },
    async addProject() {
      try {
        const {
          data: {
            ciJobTokenScopeAddProject: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: addProjectCIJobTokenScopeMutation,
          variables: {
            input: {
              projectPath: this.fullPath,
              targetProjectPath: this.targetProjectPath,
            },
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        createFlash({ message: error });
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
          mutation: removeProjectCIJobTokenScopeMutation,
          variables: {
            input: {
              projectPath: this.fullPath,
              targetProjectPath: removeTargetPath,
            },
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        createFlash({ message: error });
      } finally {
        this.getProjects();
      }
    },
    clearTargetProjectPath() {
      this.targetProjectPath = '';
    },
    getProjects() {
      this.$apollo.queries.projects.refetch();
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="$apollo.loading" size="md" class="gl-mt-5" />
    <template v-else>
      <gl-toggle
        v-model="jobTokenScopeEnabled"
        :label="$options.i18n.toggleLabelTitle"
        :help="$options.i18n.toggleHelpText"
        @change="updateCIJobTokenScope"
      />
      <div v-if="jobTokenScopeEnabled" data-testid="token-section">
        <gl-card class="gl-mt-5">
          <template #header>
            <h5 class="gl-my-0">{{ $options.i18n.cardHeaderTitle }}</h5>
          </template>
          <template #default>
            <gl-form-group :label="$options.i18n.formGroupLabel" label-for="token-project-search">
              <gl-form-input
                id="token-project-search"
                v-model="targetProjectPath"
                :placeholder="$options.i18n.addProjectPlaceholder"
              />
            </gl-form-group>
          </template>
          <template #footer>
            <gl-button
              variant="confirm"
              :disabled="isProjectPathEmpty"
              data-testid="add-project-button"
              @click="addProject"
            >
              {{ $options.i18n.addProject }}
            </gl-button>
            <gl-button @click="clearTargetProjectPath">{{ $options.i18n.cancel }}</gl-button>
          </template>
        </gl-card>

        <token-projects-table :projects="projects" @removeProject="removeProject" />
      </div>
    </template>
  </div>
</template>
