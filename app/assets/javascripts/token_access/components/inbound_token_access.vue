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
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import inboundAddGroupOrProjectCIJobTokenScope from '../graphql/mutations/inbound_add_group_or_project_ci_job_token_scope.mutation.graphql';
import inboundRemoveProjectCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_project_ci_job_token_scope.mutation.graphql';
import inboundRemoveGroupCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_group_ci_job_token_scope.mutation.graphql';
import inboundUpdateCIJobTokenScopeMutation from '../graphql/mutations/inbound_update_ci_job_token_scope.mutation.graphql';
import inboundGetCIJobTokenScopeQuery from '../graphql/queries/inbound_get_ci_job_token_scope.query.graphql';
import inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery from '../graphql/queries/inbound_get_groups_and_projects_with_ci_job_token_scope.query.graphql';
import TokenAccessTable from './token_access_table.vue';

export default {
  i18n: {
    toggleLabelTitle: s__('CICD|Limit access %{italicStart}to%{italicEnd} this project'),
    toggleDescription: s__(
      `CICD|Allow access to this project from authorized groups or projects by adding them to the allowlist. It is a security risk to disable this feature, because unauthorized projects might attempt to retrieve an active token and access the API. %{linkStart}Learn more%{linkEnd}.`,
    ),
    cardHeaderTitle: s__('CICD|Groups and projects with access'),
    settingDisabledMessage: s__(
      'CICD|Access unrestricted, so users with sufficient permissions in this project can authenticate with a job token generated in any other project. Enable this setting to restrict authentication to only job tokens generated in the groups and projects in the allowlist below.',
    ),
    addGroupOrProject: __('Add group or project'),
    add: __('Add'),
    cancel: __('Cancel'),
    addProjectPlaceholder: __(
      'Paste group path (i.e. gitlab-org) or project path (i.e. gitlab-org/gitlab)',
    ),
    projectsFetchError: __('There was a problem fetching the projects'),
    scopeFetchError: __('There was a problem fetching the job token scope value'),
  },
  fields: [
    {
      key: 'fullPath',
      label: '',
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-text-right',
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
    TokenAccessTable,
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
    groupsAndProjectsWithAccess: {
      query: inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ project }) {
        this.projects = project?.ciJobTokenScope?.inboundAllowlist?.nodes ?? [];
        this.groups = project?.ciJobTokenScope?.groupsAllowlist?.nodes ?? [];
      },
      error() {
        createAlert({ message: this.$options.i18n.projectsFetchError });
      },
    },
  },
  data() {
    return {
      inboundJobTokenScopeEnabled: null,
      targetPath: '',
      projects: [],
      groups: [],
      isAddFormVisible: false,
    };
  },
  computed: {
    isTargetPathEmpty() {
      return this.targetPath === '';
    },
    ciJobTokenHelpPage() {
      return helpPagePath('ci/jobs/ci_job_token#control-job-token-access-to-your-project');
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
            targetPath: this.targetPath,
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        createAlert({ message: error.message });
      } finally {
        this.clearTargetPath();
        this.getGroupsAndProjects();
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
    clearTargetPath() {
      this.targetPath = '';
      this.isAddFormVisible = false;
    },
    getGroupsAndProjects() {
      this.$apollo.queries.groupsAndProjectsWithAccess.refetch();
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
        class="gl-mt-5"
        @change="updateCIJobTokenScope"
      >
        <template #label>
          <gl-sprintf :message="$options.i18n.toggleLabelTitle">
            <template #italic="{ content }">
              <i>{{ content }}</i>
            </template>
          </gl-sprintf>
        </template>
        <template #description>
          <gl-sprintf :message="$options.i18n.toggleDescription" class="gl-text-secondary">
            <template #link="{ content }">
              <gl-link :href="ciJobTokenHelpPage" class="inline-link" target="_blank">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
      </gl-toggle>

      <gl-alert
        v-if="!inboundJobTokenScopeEnabled"
        variant="warning"
        class="gl-mt-6"
        :dismissible="false"
        :show-icon="false"
      >
        {{ $options.i18n.settingDisabledMessage }}
      </gl-alert>

      <div>
        <gl-card
          class="gl-new-card"
          header-class="gl-new-card-header gl-border-bottom-0"
          body-class="gl-new-card-body gl-px-0"
        >
          <template #header>
            <div class="gl-new-card-title-wrapper">
              <h5 class="gl-new-card-title">{{ $options.i18n.cardHeaderTitle }}</h5>
              <span class="gl-new-card-count">
                <gl-icon name="group" class="gl-mr-2" />
                {{ groups.length }}
              </span>
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
                >{{ $options.i18n.addGroupOrProject }}</gl-button
              >
            </div>
          </template>

          <div v-if="isAddFormVisible" class="gl-new-card-add-form gl-m-3">
            <h4 class="gl-mt-0">{{ $options.i18n.addGroupOrProject }}</h4>
            <gl-form-input
              v-model="targetPath"
              :placeholder="$options.i18n.addProjectPlaceholder"
            />
            <div class="gl-display-flex gl-mt-5">
              <gl-button
                variant="confirm"
                :disabled="isTargetPathEmpty"
                class="gl-mr-3"
                data-testid="add-project-btn"
                @click="addGroupOrProject"
              >
                {{ $options.i18n.add }}
              </gl-button>
              <gl-button @click="clearTargetPath">{{ $options.i18n.cancel }}</gl-button>
            </div>
          </div>

          <token-access-table
            :is-group="true"
            :items="groups"
            :table-fields="$options.fields"
            @removeItem="removeItem"
          />

          <token-access-table
            :items="projects"
            :table-fields="$options.fields"
            @removeItem="removeItem"
          />
        </gl-card>
      </div>
    </template>
  </div>
</template>
