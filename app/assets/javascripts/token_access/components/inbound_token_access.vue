<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlForm,
  GlFormGroup,
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
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import inboundAddGroupOrProjectCIJobTokenScope from '../graphql/mutations/inbound_add_group_or_project_ci_job_token_scope.mutation.graphql';
import inboundRemoveProjectCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_project_ci_job_token_scope.mutation.graphql';
import inboundRemoveGroupCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_group_ci_job_token_scope.mutation.graphql';
import inboundUpdateCIJobTokenScopeMutation from '../graphql/mutations/inbound_update_ci_job_token_scope.mutation.graphql';
import inboundGetCIJobTokenScopeQuery from '../graphql/queries/inbound_get_ci_job_token_scope.query.graphql';
import inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery from '../graphql/queries/inbound_get_groups_and_projects_with_ci_job_token_scope.query.graphql';
import GroupsAndProjectsListbox from './groups_and_projects_listbox.vue';
import TokenAccessTable from './token_access_table.vue';

export default {
  i18n: {
    toggleLabelTitle: s__('CICD|Limit access %{italicStart}to%{italicEnd} this project'),
    toggleDescription: s__(
      `CICD|When enabled, only groups and projects in the allowlist are authorized to use a CI/CD job token to authenticate requests to this project. When disabled, any group or project can do so. %{linkStart}Learn more%{linkEnd}.`,
    ),
    cardHeaderTitle: s__('CICD|Authorized groups and projects'),
    cardHeaderDescription: s__(
      `CICD|Ensure only groups and projects with members authorized to access sensitive project data are added to the allowlist.`,
    ),
    settingDisabledMessage: s__(
      'CICD|Access unrestricted, so users with sufficient permissions in this project can authenticate with a job token generated in any other project. Enable this setting to restrict authentication to only job tokens generated in the groups and projects in the allowlist below.',
    ),
    addGroupOrProject: __('Add group or project'),
    add: __('Add'),
    cancel: __('Cancel'),
    addProjectPlaceholder: __('Pick a group or project'),
    projectsFetchError: __('There was a problem fetching the projects'),
    scopeFetchError: __('There was a problem fetching the job token scope value'),
    projectInScopeError: s__('CICD|Target project is already in the job token scope.'),
  },
  components: {
    GlAlert,
    GlButton,
    GlCard,
    GlForm,
    GlFormGroup,
    GlLink,
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
    GlToggle,
    GroupsAndProjectsListbox,
    TokenAccessTable,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
      inboundJobTokenScopeEnabled: null,
      groupsAndProjectsWithAccess: [],
      groupOrProjectPath: '',
      projectCount: 0,
      groupCount: 0,
      isAddFormVisible: false,
    };
  },
  computed: {
    isGroupOrProjectPathEmpty() {
      return this.groupOrProjectPath === '';
    },
    isGroupOrProjectPathInScope() {
      return this.groupsAndProjectsWithAccess.some(
        (item) => item.fullPath === this.groupOrProjectPath,
      );
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
            targetPath: this.groupOrProjectPath,
          },
        });

        if (errors.length) {
          throw new Error(errors[0]);
        }
      } catch (error) {
        createAlert({ message: error.message });
      } finally {
        this.clearGroupOrProjectPath();
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
    setGroupOrProjectPath(path) {
      this.groupOrProjectPath = path;
    },
    clearGroupOrProjectPath() {
      this.groupOrProjectPath = '';
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
          header-class="gl-new-card-header gl-border-bottom-0 gl-flex-wrap gl-md-flex-nowrap"
          body-class="gl-new-card-body gl-px-0"
        >
          <template #header>
            <div class="gl-new-card-title-wrapper gl-flex-direction-column gl-flex-wrap">
              <div class="gl-new-card-title gl-items-center">
                <h5 class="gl-my-0">{{ $options.i18n.cardHeaderTitle }}</h5>
                <span
                  v-gl-tooltip
                  :title="groupCountTooltip"
                  class="gl-new-card-count"
                  data-testid="group-count"
                >
                  <gl-icon name="group" class="gl-mr-2" />
                  {{ groupCount }}
                </span>
                <span
                  v-gl-tooltip
                  :title="projectCountTooltip"
                  class="gl-new-card-count"
                  data-testid="project-count"
                >
                  <gl-icon name="project" class="gl-mr-2" />
                  {{ projectCount }}
                </span>
              </div>
              <p class="gl-text-secondary">{{ $options.i18n.cardHeaderDescription }}</p>
            </div>
            <div class="gl-new-card-actions gl-w-full gl-md-w-auto gl-text-right">
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
            <strong>{{ $options.i18n.addGroupOrProject }}</strong>
            <gl-form @submit.prevent="addGroupOrProject">
              <gl-form-group
                :state="!isGroupOrProjectPathInScope"
                :invalid-feedback="$options.projectInScopeError"
                data-testid="group-or-project-form-group"
              >
                <groups-and-projects-listbox
                  :placeholder="$options.i18n.addProjectPlaceholder"
                  :is-valid="!isGroupOrProjectPathInScope"
                  :value="groupOrProjectPath"
                  @select="setGroupOrProjectPath"
                />
              </gl-form-group>
              <div class="gl-display-flex gl-mt-5">
                <gl-button
                  variant="confirm"
                  :disabled="isGroupOrProjectPathEmpty || isGroupOrProjectPathInScope"
                  class="gl-mr-3"
                  data-testid="add-project-btn"
                  @click="addGroupOrProject"
                >
                  {{ $options.i18n.add }}
                </gl-button>
                <gl-button @click="clearGroupOrProjectPath">{{ $options.i18n.cancel }}</gl-button>
              </div>
            </gl-form>
          </div>

          <token-access-table :items="groupsAndProjectsWithAccess" @removeItem="removeItem" />
        </gl-card>
      </div>
    </template>
  </div>
</template>
