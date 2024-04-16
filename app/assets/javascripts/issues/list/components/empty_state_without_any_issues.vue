<script>
import { GlButton, GlDisclosureDropdown, GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import { i18n } from '../constants';
import { hasNewIssueDropdown } from '../has_new_issue_dropdown_mixin';
import EmptyStateWithoutAnyIssuesExperiment from './empty_state_without_any_issues_experiment.vue';

export default {
  i18n,
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
    :data-track-action="isProject && 'render_project_issues_empty_list_page'"
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
            :title="$options.i18n.noIssuesTitle"
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
                {{ $options.i18n.noIssuesDescription }}
              </gl-link>
              <p v-if="canCreateProjects">
                <strong>{{ $options.i18n.noGroupIssuesSignedInDescription }}</strong>
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
                {{ $options.i18n.newProjectLabel }}
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
                {{ $options.i18n.newIssueLabel }}
              </gl-button>

              <gl-disclosure-dropdown
                v-if="showCsvButtons"
                class="gl-mx-2 gl-mb-3"
                :toggle-text="$options.i18n.importIssues"
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
          <p class="gl-text-center gl-font-weight-bold gl-mb-0">
            {{ $options.i18n.jiraIntegrationTitle }}
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
            {{ $options.i18n.jiraIntegrationSecondaryMessage }}
          </p>
        </div>
      </template>
    </gitlab-experiment>
  </div>

  <gl-empty-state
    v-else
    :title="$options.i18n.noIssuesTitle"
    :svg-path="emptyStateSvgPath"
    :svg-height="null"
    :primary-button-text="$options.i18n.noIssuesSignedOutButtonText"
    :primary-button-link="signInPath"
    data-testid="issuable-empty-state"
  >
    <template #description>
      <gl-link :href="$options.issuesHelpPagePath">
        {{ $options.i18n.noIssuesDescription }}
      </gl-link>
    </template>
  </gl-empty-state>
</template>
