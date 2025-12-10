<script>
import {
  GlAlert,
  GlButton,
  GlCollapsibleListbox,
  GlIcon,
  GlLoadingIcon,
  GlSprintf,
  GlTooltipDirective,
  GlFormRadioGroup,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, n__, sprintf } from '~/locale';
import { TYPENAME_CI_JOB_TOKEN_ACCESSIBLE_GROUP } from '~/graphql_shared/constants';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ConfirmActionModal from '~/vue_shared/components/confirm_action_modal.vue';
import inboundRemoveProjectCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_project_ci_job_token_scope.mutation.graphql';
import inboundRemoveGroupCIJobTokenScopeMutation from '../graphql/mutations/inbound_remove_group_ci_job_token_scope.mutation.graphql';
import inboundUpdateCIJobTokenScopeMutation from '../graphql/mutations/inbound_update_ci_job_token_scope.mutation.graphql';
import inboundGetCIJobTokenScopeQuery from '../graphql/queries/inbound_get_ci_job_token_scope.query.graphql';
import getCiJobTokenScopeAllowlistQuery from '../graphql/queries/get_ci_job_token_scope_allowlist.query.graphql';
import { JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT } from '../constants';
import TokenAccessTable from './token_access_table.vue';
import NamespaceForm from './namespace_form.vue';

export default {
  i18n: {
    radioGroupDescription: s__(
      `CICD|Select the groups and projects authorized to use a CI/CD job token to authenticate requests to this project. %{linkStart}Learn more%{linkEnd}.`,
    ),
    cardHeaderTitle: s__('CICD|CI/CD job token allowlist'),
    settingDisabledMessage: s__(
      'CICD|Access unrestricted, so users with sufficient permissions in this project can authenticate with a job token generated in any other project.',
    ),
    add: __('Add'),
    projectsFetchError: __('There was a problem fetching the projects'),
    scopeFetchError: __('There was a problem fetching the job token scope value'),
    saveButtonTitle: __('Save Changes'),
    removeNamespaceModalTitle: __('Remove %{namespace}'),
    removeNamespaceModalText: s__(
      'CICD|Are you sure you want to remove %{namespace} from the job token allowlist?',
    ),
    removeNamespaceModalActionText: s__('CICD|Remove group or project'),
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
    GlCollapsibleListbox,
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
    CrudComponent,
    TokenAccessTable,
    GlFormRadioGroup,
    NamespaceForm,
    ConfirmActionModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['enforceAllowlist', 'fullPath', 'projectAllowlistLimit'],
  apollo: {
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
        return getCiJobTokenScopeAllowlistQuery;
      },
      variables() {
        return { fullPath: this.fullPath };
      },
      update({ project }) {
        const allowlist = project?.ciJobTokenScopeAllowlist;
        const groups = this.mapAllowlistNodes(allowlist?.groupsAllowlist);
        const projects = this.mapAllowlistNodes(allowlist?.projectsAllowlist);
        // Add a dummy entry for the current project. The new ciJobTokenScopeAllowlist endpoint doesn't have an entry
        // for the current project like the old ciJobTokenScope endpoint did, so we have to add it in manually, if it
        // doesn't exist yet.
        if (!projects.some(({ id }) => id === project.id))
          projects.push({ ...project, defaultPermissions: true, jobTokenPolicies: [] });

        return { projects, groups };
      },
      error() {
        createAlert({ message: this.$options.i18n.projectsFetchError });
      },
    },
  },
  data() {
    return {
      allowlistLoadingMessage: '',
      inboundJobTokenScopeEnabled: null,
      isUpdatingJobTokenScope: false,
      groupsAndProjectsWithAccess: { groups: [], projects: [] },
      projectName: '',
      namespaceToEdit: null,
      namespaceToRemove: null,
      selectedAction: null,
    };
  },
  computed: {
    isAllowlistLoading() {
      return (
        this.$apollo.queries.groupsAndProjectsWithAccess.loading ||
        this.allowlistLoadingMessage.length > 0
      );
    },
    crudFormActions() {
      const actions = [
        {
          text: __('Group or project'),
          value: JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT,
        },
      ];

      return actions;
    },
    allowlist() {
      // Show the current project at the top of the allowlist for better UX
      const { groups, projects } = this.groupsAndProjectsWithAccess;
      const allItems = [...groups, ...projects];
      const currentProject = allItems.find((item) => item.fullPath === this.fullPath);
      const otherItems = allItems
        .filter((item) => item !== currentProject)
        .sort((a, b) => a.fullPath.localeCompare(b.fullPath));
      return currentProject ? [currentProject, ...otherItems] : otherItems;
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
  },
};
</script>

<template>
  <div class="gl-mt-5">
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
    <crud-component
      :title="$options.i18n.cardHeaderTitle"
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
          placement="bottom-end"
          @select="selectAction($event, showForm)"
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
