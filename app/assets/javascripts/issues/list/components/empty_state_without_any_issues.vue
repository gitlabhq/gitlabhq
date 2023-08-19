<script>
import { GlButton, GlDisclosureDropdown, GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import { i18n } from '../constants';
import { hasNewIssueDropdown } from '../has_new_issue_dropdown_mixin';

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
  },
};
</script>

<template>
  <div v-if="isSignedIn">
    <gl-empty-state
      :title="$options.i18n.noIssuesTitle"
      :svg-path="emptyStateSvgPath"
      :svg-height="150"
    >
      <template #description>
        <gl-link :href="$options.issuesHelpPagePath">
          {{ $options.i18n.noIssuesDescription }}
        </gl-link>
        <p v-if="canCreateProjects">
          <strong>{{ $options.i18n.noGroupIssuesSignedInDescription }}</strong>
        </p>
      </template>
      <template #actions>
        <gl-button v-if="canCreateProjects" :href="newProjectPath" variant="confirm">
          {{ $options.i18n.newProjectLabel }}
        </gl-button>
        <gl-button v-if="showNewIssueLink" :href="newIssuePath" variant="confirm">
          {{ $options.i18n.newIssueLabel }}
        </gl-button>

        <gl-disclosure-dropdown
          v-if="showCsvButtons"
          class="gl-w-full gl-sm-w-auto gl-sm-mr-3"
          :toggle-text="$options.i18n.importIssues"
          data-testid="import-issues-dropdown"
        >
          <csv-import-export-buttons
            :export-csv-path="exportCsvPathWithQuery"
            :issuable-count="currentTabCount"
          />
        </gl-disclosure-dropdown>

        <new-resource-dropdown
          v-if="showNewIssueDropdown"
          class="gl-align-self-center"
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
          <gl-link :href="jiraIntegrationPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <p class="gl-text-center gl-text-secondary">
      {{ $options.i18n.jiraIntegrationSecondaryMessage }}
    </p>
  </div>

  <gl-empty-state
    v-else
    :title="$options.i18n.noIssuesTitle"
    :svg-path="emptyStateSvgPath"
    :primary-button-text="$options.i18n.noIssuesSignedOutButtonText"
    :primary-button-link="signInPath"
  >
    <template #description>
      <gl-link :href="$options.issuesHelpPagePath">
        {{ $options.i18n.noIssuesDescription }}
      </gl-link>
    </template>
  </gl-empty-state>
</template>
