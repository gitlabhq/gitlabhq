<script>
import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { s__, __ } from '~/locale';

export default {
  name: 'JiraIssuesFields',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
    JiraIssueCreationVulnerabilities: () =>
      import('ee_component/integrations/edit/components/jira_issue_creation_vulnerabilities.vue'),
  },
  props: {
    showJiraIssuesIntegration: {
      type: Boolean,
      required: false,
      default: false,
    },
    showJiraVulnerabilitiesIntegration: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialEnableJiraIssues: {
      type: Boolean,
      required: false,
      default: null,
    },
    initialEnableJiraVulnerabilities: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialVulnerabilitiesIssuetype: {
      type: String,
      required: false,
      default: undefined,
    },
    initialProjectKey: {
      type: String,
      required: false,
      default: null,
    },
    isValidated: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      enableJiraIssues: this.initialEnableJiraIssues,
      projectKey: this.initialProjectKey,
    };
  },
  computed: {
    ...mapGetters(['isInheriting']),
    checkboxDisabled() {
      return !this.showJiraIssuesIntegration || this.isInheriting;
    },
    validProjectKey() {
      return !this.enableJiraIssues || Boolean(this.projectKey) || !this.isValidated;
    },
  },
  i18n: {
    sectionDescription: s__(
      'JiraService|Work on Jira issues without leaving GitLab. Add a Jira menu to access a read-only list of your Jira issues.',
    ),
    enableCheckboxLabel: s__('JiraService|Enable Jira issues'),
    enableCheckboxHelp: s__(
      'JiraService|Warning: All GitLab users with access to this GitLab project can view all issues from the Jira project you select.',
    ),
    projectKeyLabel: s__('JiraService|Jira project key'),
    projectKeyPlaceholder: s__('JiraService|For example, AB'),
    requiredFieldFeedback: __('This field is required.'),
  },
};
</script>

<template>
  <div>
    <input name="service[issues_enabled]" type="hidden" :value="enableJiraIssues || false" />
    <gl-form-checkbox
      v-model="enableJiraIssues"
      :disabled="checkboxDisabled"
      data-qa-selector="service_jira_issues_enabled_checkbox"
    >
      {{ $options.i18n.enableCheckboxLabel }}
      <template #help>
        {{ $options.i18n.enableCheckboxHelp }}
      </template>
    </gl-form-checkbox>

    <div v-if="enableJiraIssues" class="gl-pl-6 gl-mt-3">
      <gl-form-group
        :label="$options.i18n.projectKeyLabel"
        label-for="service_project_key"
        :invalid-feedback="$options.i18n.requiredFieldFeedback"
        :state="validProjectKey"
        class="gl-max-w-26"
        data-testid="project-key-form-group"
      >
        <gl-form-input
          id="service_project_key"
          v-model="projectKey"
          name="service[project_key]"
          data-qa-selector="service_jira_project_key_field"
          :placeholder="$options.i18n.projectKeyPlaceholder"
          :required="enableJiraIssues"
          :state="validProjectKey"
          :readonly="isInheriting"
        />
      </gl-form-group>

      <jira-issue-creation-vulnerabilities
        :project-key="projectKey"
        :initial-is-enabled="initialEnableJiraVulnerabilities"
        :initial-issue-type-id="initialVulnerabilitiesIssuetype"
        :show-full-feature="showJiraVulnerabilitiesIntegration"
        class="gl-mt-6"
        data-testid="jira-for-vulnerabilities"
        @request-jira-issue-types="$emit('request-jira-issue-types')"
      />
    </div>
  </div>
</template>
