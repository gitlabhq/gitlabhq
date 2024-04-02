<script>
import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'JiraIssuesFields',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
    JiraIssueCreationVulnerabilities: () =>
      import('ee_component/integrations/edit/components/jira_issue_creation_vulnerabilities.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
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
    initialProjectKeys: {
      type: String,
      required: false,
      default: null,
    },
    isValidated: {
      type: Boolean,
      required: false,
      default: false,
    },
    isIssueCreation: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      enableJiraIssues: this.initialEnableJiraIssues,
      projectKey: this.initialProjectKey,
      projectKeys: this.initialProjectKeys,
    };
  },
  computed: {
    ...mapGetters(['isInheriting']),

    multipleProjectKeys() {
      return this.glFeatures.jiraMultipleProjectKeys;
    },

    checkboxDisabled() {
      return !this.showJiraIssuesIntegration || this.isInheriting;
    },

    validProjectKey() {
      // Allow saving the form without project_key when feature flag is enabled.
      // This will be improved in https://gitlab.com/gitlab-org/gitlab/-/issues/452161.
      if (this.multipleProjectKeys) {
        return true;
      }

      return !this.enableJiraIssues || Boolean(this.projectKey) || !this.isValidated;
    },
  },
  i18n: {
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
    <template v-if="!isIssueCreation">
      <input name="service[issues_enabled]" type="hidden" :value="enableJiraIssues || false" />
      <gl-form-checkbox
        v-model="enableJiraIssues"
        :disabled="checkboxDisabled"
        data-testid="jira-issues-enabled-checkbox"
      >
        {{ $options.i18n.enableCheckboxLabel }}
        <template #help>
          {{ $options.i18n.enableCheckboxHelp }}
        </template>
      </gl-form-checkbox>
    </template>

    <div v-if="enableJiraIssues" class="gl-pl-6 gl-mt-3">
      <gl-form-group
        v-if="multipleProjectKeys && !isIssueCreation"
        :label="s__('JiraService|Jira project keys')"
        label-for="service_project_keys"
        class="gl-max-w-26"
      >
        <gl-form-input
          id="service_project_keys"
          v-model="projectKeys"
          name="service[project_keys]"
          :placeholder="s__('JiraService|For example, AB,CD')"
          :readonly="isInheriting"
        />
      </gl-form-group>

      <template v-if="!multipleProjectKeys">
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
            data-testid="jira-project-key-field"
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
      </template>
    </div>

    <template v-if="isIssueCreation">
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
          data-testid="jira-project-key-field"
          :placeholder="$options.i18n.projectKeyPlaceholder"
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
    </template>
  </div>
</template>
