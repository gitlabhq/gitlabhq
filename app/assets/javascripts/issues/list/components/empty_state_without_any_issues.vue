<script>
import { GlButton, GlDisclosureDropdown, GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import { s__ } from '~/locale';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import { hasNewIssueDropdown } from '../has_new_issue_dropdown_mixin';
import EmptyStateWithoutAnyIssuesExperiment from './empty_state_without_any_issues_experiment.vue';

export default {
  i18n: {
    jiraIntegrationMessage: s__(
      'JiraService|%{jiraDocsLinkStart}Enable the Jira integration%{jiraDocsLinkEnd} to view your Jira issues in GitLab.',
    ),
  },
  issuesHelpPagePath: helpPagePath('user/project/issues/index'),
  components: {
    CsvImportExportButtons,
    GlButton,
    GlDisclosureDropdown,
    GlEmptyState,
    GlLink,
    GlSprintf,
    NewResourceDropdown,
    GitlabExperiment,
    EmptyStateWithoutAnyIssuesExperiment,
  },
  mixins: [hasNewIssueDropdown()],
  inject: [
    'canCreateProjects',
    'emptyStateSvgPath',
    'isSignedIn',
    'jiraIntegrationPath',
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
};
</script>

<template>
  <div
    v-if="isSignedIn"
    data-testid="signed-in-empty-state-block"
    :data-track-action="isProject && 'render'"
    :data-track-label="isProject && 'project_issues_empty_list'"
    :data-track-experiment="isProject && 'issues_mrs_empty_state'"
  >
    <gitlab-experiment name="issues_mrs_empty_state">
      <template #candidate>
        <empty-state-without-any-issues-experiment
          :show-csv-buttons="showCsvButtons"
          :show-issuable-by-email="showIssuableByEmail"
        />
      </template>

      <template #control>
        <div>
          <gl-empty-state
            :title="__('Use issues to collaborate on ideas, solve problems, and plan work')"
            :svg-path="emptyStateSvgPath"
            :svg-height="150"
            data-testid="issuable-empty-state"
          >
            <template #description>
              <gl-link
                :href="$options.issuesHelpPagePath"
                :data-track-action="isProject && 'click_learn_more_project_issues_empty_list_page'"
                :data-track-label="isProject && 'learn_more_project_issues_empty_list'"
                :data-track-experiment="isProject && 'issues_mrs_empty_state'"
              >
                {{ __('Learn more about issues.') }}
              </gl-link>
              <p v-if="canCreateProjects">
                <strong>{{
                  __('Issues exist in projects, so to create an issue, first create a project.')
                }}</strong>
              </p>
            </template>
            <template #actions>
              <!-- This component is shared between groups and projects issues list
              Now issues_mrs_empty_state experiment is run only for projects page
              If this experiment is successful new project buttons from 'control' should be
              moved to 'candidate' template to take affect for groups page as well -->
              <gl-button
                v-if="canCreateProjects"
                :href="newProjectPath"
                variant="confirm"
                class="gl-mx-2 gl-mb-3"
              >
                {{ __('New project') }}
              </gl-button>
              <gl-button
                v-if="showNewIssueLink"
                :href="newIssuePath"
                variant="confirm"
                class="gl-mx-2 gl-mb-3"
                data-track-action="click_new_issue_project_issues_empty_list_page"
                data-track-label="new_issue_project_issues_empty_list"
                data-track-experiment="issues_mrs_empty_state"
              >
                {{ __('New issue') }}
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

              <new-resource-dropdown
                v-if="showNewIssueDropdown"
                class="gl-align-self-center gl-mx-2 gl-mb-3"
                :query="$options.searchProjectsQuery"
                :query-variables="newIssueDropdownQueryVariables"
                :extract-projects="extractProjects"
                :group-id="groupId"
              />
            </template>
          </gl-empty-state>
          <hr />
          <p class="gl-text-center gl-font-bold gl-mb-0">
            {{ s__('JiraService|Using Jira for issue tracking?') }}
          </p>
          <p class="gl-text-center gl-mb-0">
            <gl-sprintf :message="$options.i18n.jiraIntegrationMessage">
              <template #jiraDocsLink="{ content }">
                <gl-link
                  :href="jiraIntegrationPath"
                  :data-track-action="isProject && 'click_jira_int_project_issues_empty_list_page'"
                  :data-track-label="isProject && 'jira_int_project_issues_empty_list'"
                  :data-track-experiment="isProject && 'issues_mrs_empty_state'"
                >
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </p>
          <p class="gl-text-center gl-text-secondary">
            {{ s__('JiraService|This feature requires a Premium plan.') }}
          </p>
        </div>
      </template>
    </gitlab-experiment>
  </div>

  <gl-empty-state
    v-else
    :title="__('Use issues to collaborate on ideas, solve problems, and plan work')"
    :svg-path="emptyStateSvgPath"
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
