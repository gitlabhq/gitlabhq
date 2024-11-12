<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlIcon,
  GlLoadingIcon,
  GlSprintf,
  GlTooltipDirective,
  GlFormRadioGroup,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, n__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import inboundAddGroupOrProjectCIJobTokenScope from '../graphql/mutations/inbound_add_group_or_project_ci_job_token_scope.mutation.graphql';
import inboundRemoveProjectCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_project_ci_job_token_scope.mutation.graphql';
import inboundRemoveGroupCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_group_ci_job_token_scope.mutation.graphql';
import inboundUpdateCIJobTokenScopeMutation from '../graphql/mutations/inbound_update_ci_job_token_scope.mutation.graphql';
import inboundGetCIJobTokenScopeQuery from '../graphql/queries/inbound_get_ci_job_token_scope.query.graphql';
import inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery from '../graphql/queries/inbound_get_groups_and_projects_with_ci_job_token_scope.query.graphql';
import TokenAccessTable from './token_access_table.vue';

export default {
  CI_JOB_TOKEN_ALLOWLIST: 'ci-job-token-allowlist',
  i18n: {
    radioGroupTitle: s__('CICD|Authorized groups and projects'),
    radioGroupDescription: s__(
      `CICD|Select the groups and projects authorized to use a CI/CD job token to authenticate requests to this project. %{linkStart}Learn more%{linkEnd}.`,
    ),
    cardHeaderTitle: s__('CICD|CI/CD job token allowlist'),
    cardHeaderDescription: s__(
      `CICD|Ensure only groups and projects with members authorized to access sensitive project data are added to the allowlist.`,
    ),
    settingDisabledMessage: s__(
      'CICD|Access unrestricted, so users with sufficient permissions in this project can authenticate with a job token generated in any other project.',
    ),
    addGroupOrProject: __('Add group or project'),
    add: __('Add'),
    cancel: __('Cancel'),
    addProjectPlaceholder: __(
      'Paste group or project path. Example: %{codeStart}gitlab-org/gitlab%{codeEnd}.',
    ),
    projectsFetchError: __('There was a problem fetching the projects'),
    scopeFetchError: __('There was a problem fetching the job token scope value'),
    saveButtonTitle: __('Save Changes'),
  },
  inboundJobTokenScopeOptions: [
    {
      value: false,
      text: s__('CICD|All groups and projects'),
    },
    {
      value: true,
      text: s__('CICD|Only this project and any groups and projects in the allowlist'),
    },
  ],
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
    CrudComponent,
    TokenAccessTable,
    GlFormRadioGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['enforceAllowlist', 'fullPath'],
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
      result({ data }) {
        this.projectName = data?.project?.name;
      },
      error() {
        createAlert({ message: this.$options.i18n.scopeFetchError });
      },
    },
    groupsAndProjectsWithAccess: {
      query: inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ project }) {
        const projects = project?.ciJobTokenScope?.inboundAllowlist?.nodes ?? [];
        const groups = project?.ciJobTokenScope?.groupsAllowlist?.nodes ?? [];

        this.projectCount = projects.length;
        this.groupCount = groups.length;

        return [...groups, ...projects];
      },
      error() {
        createAlert({ message: this.$options.i18n.projectsFetchError });
      },
    },
  },
  data() {
    return {
      errorMessage: null,
      inboundJobTokenScopeEnabled: null,
      isUpdating: false,
      groupsAndProjectsWithAccess: [],
      groupOrProjectPath: '',
      projectCount: 0,
      projectName: '',
      groupCount: 0,
    };
  },
  computed: {
    isGroupOrProjectPathEmpty() {
      return this.groupOrProjectPath === '';
    },
    ciJobTokenHelpPage() {
      return helpPagePath('ci/jobs/ci_job_token#control-job-token-access-to-your-project');
    },
    groupCountTooltip() {
      return sprintf(
        n__('%{count} group has access', '%{count} groups have access', this.groupCount),
        {
          count: this.groupCount,
        },
      );
    },
    projectCountTooltip() {
      return sprintf(
        n__('%{count} project has access', '%{count} projects have access', this.projectCount),
        {
          count: this.projectCount,
        },
      );
    },
  },
  methods: {
    async updateCIJobTokenScope() {
      this.isUpdating = true;

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

        const toastMessage = sprintf(
          __("CI/CD job token permissions for '%{projectName}' were successfully updated."),
          { projectName: this.projectName },
        );
        this.$toast.show(toastMessage);
      } catch (error) {
        this.inboundJobTokenScopeEnabled = !this.inboundJobTokenScopeEnabled;
        createAlert({ message: error.message });
      } finally {
        this.isUpdating = false;
      }
    },
    async addGroupOrProject() {
      try {
        const {
          data: {
            ciJobTokenScopeAddGroupOrProject: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: inboundAddGroupOrProjectCIJobTokenScope,
          variables: {
            projectPath: this.fullPath,
            targetPath: this.groupOrProjectPath,
          },
        });

        if (errors.length > 0) {
          throw new Error(errors[0]);
        }

        this.clearGroupOrProjectPath();
        this.getGroupsAndProjects();
      } catch (error) {
        this.errorMessage = error.message;
      }
    },
    async removeItem(item) {
      try {
        let errors;

        // eslint-disable-next-line no-underscore-dangle
        if (item.__typename === TYPENAME_GROUP) {
          const {
            data: { ciJobTokenScopeRemoveGroup },
          } = await this.$apollo.mutate({
            mutation: inboundRemoveGroupCIJobTokenScopeMutation,
            variables: {
              projectPath: this.fullPath,
              targetGroupPath: item.fullPath,
            },
          });
          errors = ciJobTokenScopeRemoveGroup.errors;
        } else {
          const {
            data: { ciJobTokenScopeRemoveProject },
          } = await this.$apollo.mutate({
            mutation: inboundRemoveProjectCIJobTokenScopeMutation,
            variables: {
              projectPath: this.fullPath,
              targetProjectPath: item.fullPath,
            },
          });
          errors = ciJobTokenScopeRemoveProject.errors;
        }

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        createAlert({ message: error.message });
      } finally {
        this.getGroupsAndProjects();
      }
    },
    clearErrorMessage() {
      this.errorMessage = null;
    },
    clearGroupOrProjectPath() {
      this.groupOrProjectPath = '';
      this.$refs.jobTokenCrud.hideForm();
    },
    getGroupsAndProjects() {
      this.$apollo.queries.groupsAndProjectsWithAccess.refetch();
    },
    showAddForm() {
      this.$refs.jobTokenCrud.showForm();
    },
  },
};
</script>
<template>
  <div class="gl-mt-5">
    <gl-loading-icon v-if="$apollo.loading" size="md" />
    <template v-else>
      <div class="gl-font-bold">
        {{ $options.i18n.radioGroupTitle }}
      </div>
      <div class="gl-mb-3">
        <gl-sprintf :message="$options.i18n.radioGroupDescription">
          <template #link="{ content }">
            <gl-link :href="ciJobTokenHelpPage" class="inline-link" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
      <gl-form-radio-group
        v-if="!enforceAllowlist"
        v-model="inboundJobTokenScopeEnabled"
        :options="$options.inboundJobTokenScopeOptions"
        stacked
      />
      <gl-alert
        v-if="!inboundJobTokenScopeEnabled && !enforceAllowlist"
        variant="warning"
        class="gl-my-3"
        :dismissible="false"
        :show-icon="false"
      >
        {{ $options.i18n.settingDisabledMessage }}
      </gl-alert>

      <gl-button
        v-if="!enforceAllowlist"
        variant="confirm"
        class="gl-mt-3"
        data-testid="save-ci-job-token-scope-changes-btn"
        :loading="isUpdating"
        @click="updateCIJobTokenScope"
      >
        {{ $options.i18n.saveButtonTitle }}
      </gl-button>

      <div>
        <crud-component
          ref="jobTokenCrud"
          :title="$options.i18n.cardHeaderTitle"
          :description="$options.i18n.cardHeaderDescription"
          class="gl-mt-5"
        >
          <template #count>
            <span class="gl-inline-flex gl-gap-3">
              <span
                v-gl-tooltip
                :title="groupCountTooltip"
                class="gl-inline-flex gl-items-center gl-gap-2 gl-text-sm gl-text-subtle"
                data-testid="group-count"
              >
                <gl-icon name="group" />
                {{ groupCount }}
              </span>
              <span
                v-gl-tooltip
                :title="projectCountTooltip"
                class="gl-inline-flex gl-items-center gl-gap-2 gl-text-sm gl-text-subtle"
                data-testid="project-count"
              >
                <gl-icon name="project" />
                {{ projectCount }}
              </span>
            </span>
          </template>

          <template #actions>
            <gl-button size="small" data-testid="toggle-form-btn" @click="showAddForm">{{
              $options.i18n.addGroupOrProject
            }}</gl-button>
          </template>

          <template #form>
            <gl-form @submit.prevent="addGroupOrProject">
              <gl-form-group
                :label-for="$options.CI_JOB_TOKEN_ALLOWLIST"
                :label="$options.i18n.addGroupOrProject"
                :invalid-feedback="errorMessage"
                data-testid="group-or-project-form-group"
              >
                <gl-form-input
                  :id="$options.CI_JOB_TOKEN_ALLOWLIST"
                  v-model="groupOrProjectPath"
                  autofocus
                  :state="!errorMessage"
                  type="text"
                  data-testid="target-path-field"
                  @input="clearErrorMessage"
                />
                <template #description>
                  <gl-sprintf :message="$options.i18n.addProjectPlaceholder">
                    <template #code="{ content }">
                      <code>{{ content }}</code>
                    </template>
                  </gl-sprintf>
                </template>
              </gl-form-group>
              <div class="gl-mt-5 gl-flex gl-gap-3">
                <gl-button
                  variant="confirm"
                  :disabled="isGroupOrProjectPathEmpty"
                  data-testid="add-group-or-project-btn"
                  @click="addGroupOrProject"
                >
                  {{ $options.i18n.add }}
                </gl-button>
                <gl-button @click="clearGroupOrProjectPath">{{ $options.i18n.cancel }}</gl-button>
              </div>
            </gl-form>
          </template>

          <token-access-table :items="groupsAndProjectsWithAccess" @removeItem="removeItem" />
        </crud-component>
      </div>
    </template>
  </div>
</template>
