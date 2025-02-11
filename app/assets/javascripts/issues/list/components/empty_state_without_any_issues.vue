<script>
import emptyStateSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-issues-add-md.svg';
import { GlButton, GlDisclosureDropdown, GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import { s__, __ } from '~/locale';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import { hasNewIssueDropdown } from '../has_new_issue_dropdown_mixin';

export default {
  i18n: {
    jiraIntegrationMessage: s__(
      'JiraService|%{jiraDocsLinkStart}Enable the Jira integration%{jiraDocsLinkEnd} to view your Jira issues in GitLab.',
    ),
  },
  emptyStateSvg,
  issuesHelpPagePath: helpPagePath('user/project/issues/_index'),
  jiraIntegrationPath: helpPagePath('integration/jira/configure', { anchor: 'view-jira-issues' }),
  components: {
    CsvImportExportButtons,
    GlButton,
    GlDisclosureDropdown,
    GlEmptyState,
    GlLink,
    GlSprintf,
    NewResourceDropdown,
  },
  mixins: [hasNewIssueDropdown()],
  inject: [
    'canCreateProjects',
    'isSignedIn',
    'newIssuePath',
    'newProjectPath',
    'showNewIssueLink',
    'signInPath',
    'groupId',
    'isProject',
  ],
  props: {
    currentTabCount: {
      type: Number,
      required: false,
      default: undefined,
    },
    exportCsvPathWithQuery: {
      type: String,
      required: false,
      default: '',
    },
    showCsvButtons: {
      type: Boolean,
      required: false,
      default: false,
    },
    showNewIssueDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    showIssuableByEmail: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    createProjectMessage() {
      return this.showNewIssueDropdown
        ? __('Issues exist in projects. Select a project to create an issue, or create a project.')
        : __('Issues exist in projects. To create an issue, first create a project.');
    },
  },
};
</script>

<template>
  <div
    v-if="isSignedIn"
    data-testid="signed-in-empty-state-block"
    :data-track-action="isProject && 'render'"
    :data-track-label="isProject && 'project_issues_empty_list'"
  >
    <div>
      <gl-empty-state
        :title="__('Use issues to collaborate on ideas, solve problems, and plan work')"
        :svg-path="$options.emptyStateSvg"
        data-testid="issuable-empty-state"
      >
        <template #description>
          <p
            v-if="canCreateProjects"
            data-testid="create-project-message"
            class="gl-my-2 gl-text-subtle"
          >
            {{ createProjectMessage }}
          </p>
          <gl-link
            :href="$options.issuesHelpPagePath"
            :data-track-action="isProject && 'click_learn_more_project_issues_empty_list_page'"
            :data-track-label="isProject && 'learn_more_project_issues_empty_list'"
          >
            {{ __('Learn more about issues.') }}
          </gl-link>
        </template>
        <template #actions>
          <slot name="actions"></slot>
          <new-resource-dropdown
            v-if="showNewIssueDropdown"
            class="gl-mx-2 gl-mb-3 gl-self-center"
            :query="$options.searchProjectsQuery"
            :query-variables="newIssueDropdownQueryVariables"
            :extract-projects="extractProjects"
            :group-id="groupId"
          />
          <slot name="new-issue-button">
            <gl-button
              v-if="showNewIssueLink"
              :href="newIssuePath"
              variant="confirm"
              class="gl-mx-2 gl-mb-3"
              data-track-action="click_new_issue_project_issues_empty_list_page"
              data-track-label="new_issue_project_issues_empty_list"
            >
              {{ __('New issue') }}
            </gl-button>
          </slot>
          <gl-button
            v-if="canCreateProjects"
            :href="newProjectPath"
            :variant="showNewIssueDropdown ? 'default' : 'confirm'"
            class="gl-mx-2 gl-mb-3"
          >
            {{ __('New project') }}
          </gl-button>

          <gl-disclosure-dropdown
            v-if="showCsvButtons"
            class="gl-mx-2 gl-mb-3"
            :toggle-text="__('Import issues')"
            data-testid="import-issues-dropdown"
          >
            <csv-import-export-buttons
              :export-csv-path="exportCsvPathWithQuery"
              :issuable-count="currentTabCount"
              track-import-click
            />
          </gl-disclosure-dropdown>
        </template>
      </gl-empty-state>
      <hr />
      <p class="gl-mb-0 gl-text-center gl-font-bold">
        {{ s__('JiraService|Using Jira for issue tracking?') }}
      </p>
      <p class="gl-mb-0 gl-text-center">
        <gl-sprintf :message="$options.i18n.jiraIntegrationMessage">
          <template #jiraDocsLink="{ content }">
            <gl-link
              :href="$options.jiraIntegrationPath"
              :data-track-action="isProject && 'click_jira_int_project_issues_empty_list_page'"
              :data-track-label="isProject && 'jira_int_project_issues_empty_list'"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
      <p class="gl-text-center gl-text-subtle">
        {{ s__('JiraService|This feature requires a Premium plan.') }}
      </p>
    </div>
  </div>

  <gl-empty-state
    v-else
    :title="__('Use issues to collaborate on ideas, solve problems, and plan work')"
    :svg-path="$options.emptyStateSvg"
    :svg-height="null"
    :primary-button-text="__('Register / Sign In')"
    :primary-button-link="signInPath"
    data-testid="issuable-empty-state"
  >
    <template #description>
      <gl-link :href="$options.issuesHelpPagePath">
        {{ __('Learn more about issues.') }}
      </gl-link>
    </template>
  </gl-empty-state>
</template>
