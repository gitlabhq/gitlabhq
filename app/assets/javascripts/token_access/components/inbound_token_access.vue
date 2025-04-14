<script>
import {
  GlAlert,
  GlButton,
  GlCollapsibleListbox,
  GlDisclosureDropdown,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlTooltipDirective,
  GlFormRadioGroup,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, n__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { TYPENAME_CI_JOB_TOKEN_ACCESSIBLE_GROUP } from '~/graphql_shared/constants';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ConfirmActionModal from '~/vue_shared/components/confirm_action_modal.vue';
import inboundRemoveProjectCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_project_ci_job_token_scope.mutation.graphql';
import inboundRemoveGroupCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_group_ci_job_token_scope.mutation.graphql';
import inboundUpdateCIJobTokenScopeMutation from '../graphql/mutations/inbound_update_ci_job_token_scope.mutation.graphql';
import inboundGetCIJobTokenScopeQuery from '../graphql/queries/inbound_get_ci_job_token_scope.query.graphql';
import inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery from '../graphql/queries/inbound_get_groups_and_projects_with_ci_job_token_scope.query.graphql';
import autopopulateAllowlistMutation from '../graphql/mutations/autopopulate_allowlist.mutation.graphql';
import getCiJobTokenScopeAllowlistQuery from '../graphql/queries/get_ci_job_token_scope_allowlist.query.graphql';
import getAuthLogCountQuery from '../graphql/queries/get_auth_log_count.query.graphql';
import removeAutopopulatedEntriesMutation from '../graphql/mutations/remove_autopopulated_entries.mutation.graphql';
import {
  JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT,
  JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG,
  JOB_TOKEN_REMOVE_AUTOPOPULATED_ENTRIES_MODAL,
} from '../constants';
import TokenAccessTable from './token_access_table.vue';
import NamespaceForm from './namespace_form.vue';
import AutopopulateAllowlistModal from './autopopulate_allowlist_modal.vue';
import RemoveAutopopulatedEntriesModal from './remove_autopopulated_entries_modal.vue';

export default {
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
    add: __('Add'),
    addGroupOrProject: __('Add group or project'),
    projectsFetchError: __('There was a problem fetching the projects'),
    scopeFetchError: __('There was a problem fetching the job token scope value'),
    saveButtonTitle: __('Save Changes'),
    removeNamespaceModalTitle: __('Remove %{namespace}'),
    removeNamespaceModalText: s__(
      'CICD|Are you sure you want to remove %{namespace} from the job token allowlist?',
    ),
    removeNamespaceModalActionText: s__('CICD|Remove group or project'),
    removeAutopopulatedEntries: s__('CICD|Remove all auto-added allowlist entries'),
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
    AutopopulateAllowlistModal,
    GlAlert,
    GlButton,
    GlCollapsibleListbox,
    GlDisclosureDropdown,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    CrudComponent,
    RemoveAutopopulatedEntriesModal,
    TokenAccessTable,
    GlFormRadioGroup,
    NamespaceForm,
    ConfirmActionModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['enforceAllowlist', 'fullPath', 'projectAllowlistLimit', 'isJobTokenPoliciesEnabled'],
  apollo: {
    authLogCount: {
      query: getAuthLogCountQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ project }) {
        return project.ciJobTokenAuthLogs?.count;
      },
      error() {
        createAlert({
          message: s__('CICD|There was a problem fetching authorization logs count.'),
        });
      },
    },
    inboundJobTokenScopeEnabled: {
      query: inboundGetCIJobTokenScopeQuery,
      variables() {
        return { fullPath: this.fullPath };
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
      query() {
        return this.isJobTokenPoliciesEnabled
          ? getCiJobTokenScopeAllowlistQuery
          : inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery;
      },
      variables() {
        return { fullPath: this.fullPath };
      },
      update({ project }) {
        let groups;
        let projects;

        if (this.isJobTokenPoliciesEnabled) {
          const allowlist = project?.ciJobTokenScopeAllowlist;
          groups = this.mapAllowlistNodes(allowlist?.groupsAllowlist);
          projects = this.mapAllowlistNodes(allowlist?.projectsAllowlist);
          // Add a dummy entry for the current project. The new ciJobTokenScopeAllowlist endpoint doesn't have an entry
          // for the current project like the old ciJobTokenScope endpoint did, so we have to add it in manually.
          projects.push({ ...project, defaultPermissions: true, jobTokenPolicies: [] });
        } else {
          projects = project?.ciJobTokenScope?.inboundAllowlist?.nodes ?? [];
          groups = project?.ciJobTokenScope?.groupsAllowlist?.nodes ?? [];
          const groupAllowlistAutopopulatedIds =
            project?.ciJobTokenScope?.groupAllowlistAutopopulatedIds ?? [];
          const inboundAllowlistAutopopulatedIds =
            project?.ciJobTokenScope?.inboundAllowlistAutopopulatedIds ?? [];

          projects = this.addAutopopulatedAttribute(projects, inboundAllowlistAutopopulatedIds);
          groups = this.addAutopopulatedAttribute(groups, groupAllowlistAutopopulatedIds);
        }

        return { projects, groups };
      },
      error() {
        createAlert({ message: this.$options.i18n.projectsFetchError });
      },
    },
  },
  data() {
    return {
      authLogCount: 0,
      allowlistLoadingMessage: '',
      inboundJobTokenScopeEnabled: null,
      isUpdatingJobTokenScope: false,
      groupsAndProjectsWithAccess: { groups: [], projects: [] },
      autopopulationErrorMessage: null,
      projectName: '',
      namespaceToEdit: null,
      namespaceToRemove: null,
      selectedAction: null,
    };
  },
  computed: {
    authLogExceedsLimit() {
      return this.projectCount + this.groupCount + this.authLogCount > this.projectAllowlistLimit;
    },
    isAllowlistLoading() {
      return (
        this.$apollo.queries.groupsAndProjectsWithAccess.loading ||
        this.allowlistLoadingMessage.length > 0
      );
    },
    ciJobTokenHelpPage() {
      return helpPagePath('ci/jobs/ci_job_token', {
        anchor: 'control-job-token-access-to-your-project',
      });
    },
    crudFormActions() {
      const actions = [
        {
          text: __('Group or project'),
          value: JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT,
        },
      ];

      if (this.authLogCount > 0) {
        actions.push({
          text: __('All projects in authentication log'),
          value: JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG,
        });
      }

      return actions;
    },
    allowlist() {
      const { groups, projects } = this.groupsAndProjectsWithAccess;
      return [...groups, ...projects];
    },
    disclosureDropdownOptions() {
      return [
        {
          text: this.$options.i18n.removeAutopopulatedEntries,
          variant: 'danger',
          action: () => {
            this.selectedAction = JOB_TOKEN_REMOVE_AUTOPOPULATED_ENTRIES_MODAL;
          },
        },
      ];
    },
    hasAutoPopulatedEntries() {
      return this.allowlist.filter((entry) => entry.autopopulated).length > 0;
    },
    groupCount() {
      return this.groupsAndProjectsWithAccess.groups.length;
    },
    projectCount() {
      return this.groupsAndProjectsWithAccess.projects.length;
    },
    groupCountTooltip() {
      return n__('%d group has access', '%d groups have access', this.groupCount);
    },
    projectCountTooltip() {
      return n__('%d project has access', '%d projects have access', this.projectCount);
    },
    removeNamespaceModalTitle() {
      return sprintf(this.$options.i18n.removeNamespaceModalTitle, {
        namespace: this.namespaceToRemove?.fullPath,
      });
    },
    showRemoveAutopopulatedEntriesModal() {
      return this.selectedAction === JOB_TOKEN_REMOVE_AUTOPOPULATED_ENTRIES_MODAL;
    },
    showAutopopulateModal() {
      return this.selectedAction === JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG;
    },
  },
  methods: {
    hideSelectedAction() {
      this.namespaceToEdit = null;
      this.selectedAction = null;
    },
    mapAllowlistNodes(list) {
      // The defaultPermissions and jobTokenPolicies are separate fields from the target (the group or project in the
      // allowlist). Combine them into a single object.
      return list.nodes.map((node) => ({
        ...node.target,
        defaultPermissions: node.defaultPermissions,
        jobTokenPolicies: node.jobTokenPolicies,
        autopopulated: node.autopopulated,
      }));
    },
    async updateCIJobTokenScope() {
      this.isUpdatingJobTokenScope = true;

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
        this.isUpdatingJobTokenScope = false;
      }
    },
    async removeItem() {
      const { __typename, fullPath } = this.namespaceToRemove;
      const mutation =
        __typename === TYPENAME_CI_JOB_TOKEN_ACCESSIBLE_GROUP
          ? inboundRemoveGroupCIJobTokenScopeMutation
          : inboundRemoveProjectCIJobTokenScopeMutation;

      const response = await this.$apollo.mutate({
        mutation,
        variables: { projectPath: this.fullPath, targetPath: fullPath },
      });

      const error = response.data.removeNamespace.errors[0];
      if (error) {
        return Promise.reject(error);
      }

      this.refetchGroupsAndProjects();
      return Promise.resolve();
    },
    async autopopulateAllowlist() {
      this.hideSelectedAction();
      this.autopopulationErrorMessage = null;
      this.allowlistLoadingMessage = s__(
        'CICD|Auto-populating allowlist entries. Please wait while the action completes.',
      );

      try {
        const {
          data: {
            ciJobTokenScopeAutopopulateAllowlist: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: autopopulateAllowlistMutation,
          variables: {
            projectPath: this.fullPath,
          },
        });

        if (errors.length) {
          this.autopopulationErrorMessage = errors[0].message;
          return;
        }

        this.$apollo.queries.inboundJobTokenScopeEnabled.refetch();
        this.refetchAllowlist();
        this.$toast.show(
          s__('CICD|Authentication log entries were successfully added to the allowlist.'),
        );
      } catch {
        this.autopopulationErrorMessage = s__(
          'CICD|An error occurred while adding the authentication log entries. Please try again.',
        );
      } finally {
        this.allowlistLoadingMessage = '';
      }
    },
    async removeAutopopulatedEntries() {
      this.hideSelectedAction();
      this.autopopulationErrorMessage = null;
      this.allowlistLoadingMessage = s__(
        'CICD|Removing auto-added allowlist entries. Please wait while the action completes.',
      );

      try {
        const {
          data: {
            ciJobTokenScopeClearAllowlistAutopopulations: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: removeAutopopulatedEntriesMutation,
          variables: {
            projectPath: this.fullPath,
          },
        });

        if (errors.length) {
          this.autopopulationErrorMessage = errors[0].message;
          return;
        }

        this.refetchAllowlist();
        this.$toast.show(
          s__('CICD|Authentication log entries were successfully removed from the allowlist.'),
        );
      } catch (error) {
        this.autopopulationErrorMessage = s__(
          'CICD|An error occurred while removing the auto-added log entries. Please try again.',
        );
      } finally {
        this.allowlistLoadingMessage = '';
      }
    },
    refetchAllowlist() {
      this.$apollo.queries.groupsAndProjectsWithAccess.refetch();
      this.hideSelectedAction();
    },
    refetchGroupsAndProjects() {
      this.$apollo.queries.groupsAndProjectsWithAccess.refetch();
    },
    selectAction(action, showFormFn) {
      this.selectedAction = action;
      if (action === JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT) {
        showFormFn();
      }
    },
    showNamespaceForm(namespace, showFormFn) {
      this.namespaceToEdit = namespace;
      showFormFn();
    },
    addAutopopulatedAttribute(collection, idList) {
      return collection.map((item) => ({
        ...item,
        autopopulated: idList.includes(item.id),
      }));
    },
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <autopopulate-allowlist-modal
      :auth-log-exceeds-limit="authLogExceedsLimit"
      :project-allowlist-limit="projectAllowlistLimit"
      :project-name="projectName"
      :show-modal="showAutopopulateModal"
      @hide="hideSelectedAction"
      @autopopulate-allowlist="autopopulateAllowlist"
    />
    <remove-autopopulated-entries-modal
      :show-modal="showRemoveAutopopulatedEntriesModal"
      @hide="hideSelectedAction"
      @remove-entries="removeAutopopulatedEntries"
    />
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
      :loading="isUpdatingJobTokenScope"
      @click="updateCIJobTokenScope"
    >
      {{ $options.i18n.saveButtonTitle }}
    </gl-button>
    <gl-alert
      v-if="autopopulationErrorMessage"
      variant="danger"
      class="gl-my-5"
      :dismissible="false"
      data-testid="autopopulation-alert"
    >
      {{ autopopulationErrorMessage }}
    </gl-alert>
    <crud-component
      :title="$options.i18n.cardHeaderTitle"
      :description="$options.i18n.cardHeaderDescription"
      class="gl-mt-5"
      @hideForm="hideSelectedAction"
    >
      <template #actions="{ showForm }">
        <gl-collapsible-listbox
          v-model="selectedAction"
          :items="crudFormActions"
          :toggle-text="$options.i18n.add"
          data-testid="form-selector"
          size="small"
          @select="selectAction($event, showForm)"
        />
        <gl-disclosure-dropdown
          v-if="hasAutoPopulatedEntries"
          category="tertiary"
          icon="ellipsis_v"
          no-caret
          :items="disclosureDropdownOptions"
        />
      </template>
      <template #count>
        <gl-loading-icon v-if="isAllowlistLoading" data-testid="count-loading-icon" />
        <template v-else>
          <span
            v-gl-tooltip.d0="groupCountTooltip"
            class="gl-cursor-default"
            data-testid="group-count"
          >
            <gl-icon name="group" /> {{ groupCount }}
          </span>
          <span
            v-gl-tooltip.d0="projectCountTooltip"
            class="gl-ml-2 gl-cursor-default"
            data-testid="project-count"
          >
            <gl-icon name="project" /> {{ projectCount }}
          </span>
        </template>
      </template>

      <template #form="{ hideForm }">
        <namespace-form
          :namespace="namespaceToEdit"
          @saved="refetchGroupsAndProjects"
          @close="hideForm"
        />
      </template>

      <template #default="{ showForm }">
        <token-access-table
          :items="allowlist"
          :loading="isAllowlistLoading"
          :loading-message="allowlistLoadingMessage"
          :show-policies="isJobTokenPoliciesEnabled"
          @editItem="showNamespaceForm($event, showForm)"
          @removeItem="namespaceToRemove = $event"
        />

        <confirm-action-modal
          v-if="namespaceToRemove"
          modal-id="inbound-token-access-remove-confirm-modal"
          :title="removeNamespaceModalTitle"
          :action-fn="removeItem"
          :action-text="$options.i18n.removeNamespaceModalActionText"
          @close="namespaceToRemove = null"
        >
          <gl-sprintf :message="$options.i18n.removeNamespaceModalText">
            <template #namespace>
              <code>{{ namespaceToRemove.fullPath }}</code>
            </template>
          </gl-sprintf>
        </confirm-action-modal>
      </template>
    </crud-component>
  </div>
</template>
