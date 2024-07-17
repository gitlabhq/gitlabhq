<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlLink,
  GlIcon,
  GlLoadingIcon,
  GlSprintf,
  GlToggle,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, n__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import addProjectCIJobTokenScopeMutation from '../graphql/mutations/add_project_ci_job_token_scope.mutation.graphql';
import removeProjectCIJobTokenScopeMutation from '../graphql/mutations/remove_project_ci_job_token_scope.mutation.graphql';
import updateCIJobTokenScopeMutation from '../graphql/mutations/update_ci_job_token_scope.mutation.graphql';
import getCIJobTokenScopeQuery from '../graphql/queries/get_ci_job_token_scope.query.graphql';
import getProjectsWithCIJobTokenScopeQuery from '../graphql/queries/get_projects_with_ci_job_token_scope.query.graphql';
import TokenAccessTable from './token_access_table.vue';

// Note: This component will be removed in 18.0, as the outbound access token is getting deprecated
export default {
  i18n: {
    toggleLabelTitle: s__(
      'CICD|Limit access %{italicStart}from%{italicEnd} this project (Deprecated)',
    ),
    toggleHelpText: s__(
      `CICD|Prevent CI/CD job tokens from this project from being used to access other projects unless the other project is added to the allowlist. It is a security risk to disable this feature, because unauthorized projects might attempt to retrieve an active token and access the API. %{linkStart}Learn more%{linkEnd}.`,
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
    outboundTokenAlertDeprecationMessage: s__(
      `CICD|The %{boldStart}Limit access %{boldEnd}%{italicAndBoldStart}from%{italicAndBoldEnd}%{boldStart} this project%{boldEnd} setting is deprecated and will be removed in the 18.0 milestone. Use the %{boldStart}Limit access %{boldEnd}%{italicAndBoldStart}to%{italicAndBoldEnd}%{boldStart} this project%{boldEnd} setting and allowlist instead. %{linkStart}How do I do this?%{linkEnd}`,
    ),
    disableToggleWarning: s__('CICD|Disabling this feature is a permanent change.'),
  },
  // eslint-disable-next-line local-rules/require-valid-help-page-path
  deprecationDocumentationLink: helpPagePath('ci/jobs/ci_job_token', {
    anchor: 'limit-your-projects-job-token-access',
  }),
  components: {
    GlAlert,
    GlButton,
    GlCard,
    GlLink,
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
    GlToggle,
    TokenAccessTable,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
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
      // eslint-disable-next-line local-rules/require-valid-help-page-path
      return helpPagePath('ci/jobs/ci_job_token#limit-your-projects-job-token-access');
    },
    disableTokenToggle() {
      return !this.jobTokenScopeEnabled;
    },
    projectCountTooltip() {
      return sprintf(
        n__('%{count} project has access', '%{count} projects have access', this.projects.length),
        {
          count: this.projects.length,
        },
      );
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
    async removeProject(project) {
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
              targetProjectPath: project.fullPath,
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
      <gl-alert
        class="gl-mt-5 gl-mb-3"
        variant="warning"
        :dismissible="false"
        :show-icon="false"
        data-testid="deprecation-alert"
      >
        <gl-sprintf :message="$options.i18n.outboundTokenAlertDeprecationMessage">
          <template #bold="{ content }">
            <strong>{{ content }}</strong>
          </template>
          <template #italicAndBold="{ content }">
            <i
              ><strong>{{ content }}</strong></i
            >
          </template>
          <template #link="{ content }">
            <gl-link
              :href="$options.deprecationDocumentationLink"
              class="inline-link"
              target="_blank"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>
      <gl-toggle
        v-model="jobTokenScopeEnabled"
        :label="$options.i18n.toggleLabelTitle"
        :disabled="disableTokenToggle"
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
              <gl-link :href="ciJobTokenHelpPage" class="inline-link" target="_blank">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
          <strong>{{ $options.i18n.disableToggleWarning }} </strong>
        </template>
      </gl-toggle>

      <div>
        <gl-card
          class="gl-new-card"
          header-class="gl-new-card-header gl-border-b-0"
          body-class="gl-new-card-body gl-px-0"
        >
          <template #header>
            <div class="gl-new-card-title-wrapper">
              <h5 class="gl-new-card-title">{{ $options.i18n.cardHeaderTitle }}</h5>
              <span v-gl-tooltip :title="projectCountTooltip" class="gl-new-card-count">
                <gl-icon name="project" class="gl-mr-2" />
                {{ projects.length }}
              </span>
            </div>
            <div class="gl-new-card-actions">
              <gl-button size="small" disabled>{{ $options.i18n.addProject }}</gl-button>
            </div>
          </template>
          <token-access-table :items="projects" @removeItem="removeProject" />
        </gl-card>
      </div>
    </template>
  </div>
</template>
