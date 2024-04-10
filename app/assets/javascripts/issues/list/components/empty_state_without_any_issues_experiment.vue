<script>
import { GlButton, GlModalDirective, GlIcon } from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import CsvImportModal from '~/issuable/components/csv_import_modal.vue';
import { i18n } from '../constants';
import GlCardEmptyStateExperiment from './gl_card_empty_state_experiment.vue';

export default {
  i18n,
  issuesHelpPagePath: helpPagePath('user/project/issues/index'),
  components: {
    GlCardEmptyStateExperiment,
    GlButton,
    GlIcon,
    IssuableByEmail,
    CsvImportModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: {
    jiraIntegrationPath: {
      default: null,
    },
    newIssuePath: {
      default: null,
    },
    showNewIssueLink: {
      default: false,
    },
    showImportButton: {
      default: false,
    },
    canEdit: {
      default: false,
    },
    projectImportJiraPath: {
      default: null,
    },
  },
  props: {
    showCsvButtons: {
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
    importModalId() {
      return `${TYPE_ISSUE}-import-modal`;
    },
  },
};
</script>

<template>
  <div class="gl-text-center gl-empty-state">
    <iframe
      class="video-container gl-h-auto gl-w-full"
      src="https://www.youtube-nocookie.com/embed/-4SGhGpwZDY?si=Ym-29hpY22cgdGdH"
      title="Create an Issue - The basics"
      frameborder="0"
      allow="accelerometer; encrypted-media; gyroscope;"
      sandbox="allow-scripts allow-same-origin allow-presentation"
      data-testid="create-an-issue-iframe-video"
      allowfullscreen
    ></iframe>

    <h1 class="gl-font-size-h-display gl-max-w-75 gl-m-auto gl-pt-8">
      {{ $options.i18n.noIssuesTitle }}
    </h1>

    <p class="gl-max-w-75 gl-m-auto gl-pt-4 gl-pb-5">
      {{
        __(
          'With issues you can discuss the implementation of an idea, track tasks and work status, elaborate on code implementations, and accept feature proposals, questions, support requests, or bug reports.',
        )
      }}
    </p>

    <div
      class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-justify-content-center gl-gap-3"
    >
      <gl-button
        v-if="showNewIssueLink"
        :href="newIssuePath"
        variant="confirm"
        data-testid="empty-state-new-issue-btn"
        data-track-action="click_new_issue_project_issues_empty_list_page"
        data-track-label="new_issue_project_issues_empty_list"
        data-track-experiment="issues_mrs_empty_state"
      >
        {{ __('Create a new issue') }}
      </gl-button>

      <issuable-by-email
        v-if="showIssuableByEmail"
        button-class="gl-w-full"
        variant="default"
        :text="__('Email a new issue')"
        data-track-action="click_email_issue_project_issues_empty_list_page"
        data-track-label="email_issue_project_issues_empty_list"
        data-track-experiment="issues_mrs_empty_state"
      />
    </div>

    <div class="gl-display-flex gl-flex-direction-column gl-gap-6 gl-max-w-88 gl-mx-auto gl-pt-9">
      <div
        class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-justify-content-center gl-gap-6"
      >
        <gl-card-empty-state-experiment v-if="showCsvButtons && showImportButton" icon="download">
          <template #header>
            {{ __('Import existing issues') }}
          </template>
          <template #body>
            <csv-import-modal :modal-id="importModalId" />

            <div class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-gap-3">
              <gl-button
                v-gl-modal="importModalId"
                class="gl-mt-3 gl-ml-0! gl-mb-0!"
                data-testid="empty-state-import-csv-btn"
                data-track-action="click_import_csv_project_issues_empty_list_page"
                data-track-label="import_csv_project_issues_empty_list"
                data-track-experiment="issues_mrs_empty_state"
              >
                {{ __('Import CSV') }}
              </gl-button>

              <gl-button
                v-if="canEdit"
                class="gl-mt-3 gl-mb-0!"
                :href="projectImportJiraPath"
                data-testid="empty-state-import-jira-btn"
                data-track-action="click_import_jira_project_issues_empty_list_page"
                data-track-label="import_jira_project_issues_empty_list"
                data-track-experiment="issues_mrs_empty_state"
              >
                {{ __('Import from Jira') }}
              </gl-button>
            </div>
          </template>
        </gl-card-empty-state-experiment>

        <a
          class="gl-text-decoration-none!"
          :href="$options.issuesHelpPagePath"
          data-testid="empty-state-learn-more-link"
          data-track-action="click_learn_more_project_issues_empty_list_page"
          data-track-label="learn_more_project_issues_empty_list"
          data-track-experiment="issues_mrs_empty_state"
        >
          <gl-card-empty-state-experiment
            class="gl-h-13 gl-justify-content-center gl-hover-text-blue-600 gl-text-gray-900"
            icon="issue-type-issue"
          >
            <template #header>
              {{ __('Learn more about issues') }}
              <gl-icon class="gl-display-inline gl-ml-2" name="arrow-right" />
            </template>

            <template #body>
              <span class="gl-text-gray-900">{{ __('Read our documentation') }}</span>
            </template>
          </gl-card-empty-state-experiment>
        </a>
      </div>

      <div
        class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-justify-content-center"
      >
        <a
          class="gl-text-decoration-none!"
          :href="jiraIntegrationPath"
          data-testid="empty-state-jira-int-link"
          data-track-action="click_jira_int_project_issues_empty_list_page"
          data-track-label="jira_int_project_issues_empty_list"
          data-track-experiment="issues_mrs_empty_state"
        >
          <gl-card-empty-state-experiment
            class="gl-h-13 gl-hover-text-blue-600 gl-text-gray-900"
            icon="api"
          >
            <template #header>
              {{ __('Enable Jira integration') }}
              <gl-icon class="gl-display-inline gl-ml-2" name="arrow-right" />
            </template>

            <template #body>
              <span class="gl-text-gray-900">
                {{ __('This feature is only available on paid plans.') }}
              </span>
            </template>
          </gl-card-empty-state-experiment>
        </a>
      </div>
    </div>
  </div>
</template>
