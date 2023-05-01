<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlFormInput,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlToggle,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
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
      `CICD|Select the projects that can be accessed by API requests authenticated with this project's CI_JOB_TOKEN CI/CD variable. It is a security risk to disable this feature, because unauthorized projects might attempt to retrieve an active token and access the API. %{linkStart}Learn more.%{linkEnd}`,
    ),
    cardHeaderTitle: s__('CICD|Add an existing project to the scope'),
    settingDisabledMessage: s__(
      'CICD|Enable feature to limit job token access to the following projects.',
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
      label: __('Project that can be accessed'),
      thClass: 'gl-border-t-none!',
      columnClass: 'gl-w-40p',
    },
    {
      key: 'namespace',
      label: __('Namespace'),
      thClass: 'gl-border-t-none!',
      columnClass: 'gl-w-40p',
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-text-right',
      thClass: 'gl-border-t-none!',
      columnClass: 'gl-w-10p',
    },
  ],
  components: {
    GlAlert,
    GlButton,
    GlCard,
    GlFormInput,
    GlLink,
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
        createAlert({ message: this.$options.i18n.scopeFetchError });
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
        createAlert({ message: this.$options.i18n.projectsFetchError });
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
    ciJobTokenHelpPage() {
      return helpPagePath('ci/jobs/ci_job_token#limit-your-projects-job-token-access');
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
        createAlert({ message: error.message });
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
    <gl-loading-icon v-if="$apollo.loading" size="lg" class="gl-mt-5" />
    <template v-else>
      <gl-toggle
        v-model="jobTokenScopeEnabled"
        :label="$options.i18n.toggleLabelTitle"
        @change="updateCIJobTokenScope"
      >
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
        <gl-card class="gl-mt-5 gl-mb-3">
          <template #header>
            <h5 class="gl-my-0">{{ $options.i18n.cardHeaderTitle }}</h5>
          </template>
          <template #default>
            <gl-form-input
              v-model="targetProjectPath"
              :placeholder="$options.i18n.addProjectPlaceholder"
            />
          </template>
          <template #footer>
            <gl-button variant="confirm" :disabled="isProjectPathEmpty" @click="addProject">
              {{ $options.i18n.addProject }}
            </gl-button>
            <gl-button @click="clearTargetProjectPath">{{ $options.i18n.cancel }}</gl-button>
          </template>
        </gl-card>
        <gl-alert
          v-if="!jobTokenScopeEnabled"
          class="gl-mb-3"
          variant="warning"
          :dismissible="false"
          :show-icon="false"
          data-testid="token-disabled-alert"
        >
          {{ $options.i18n.settingDisabledMessage }}
        </gl-alert>
        <token-projects-table
          :projects="projects"
          :table-fields="$options.fields"
          @removeProject="removeProject"
        />
      </div>
    </template>
  </div>
</template>
