<script>
import { GlFormGroup, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
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
    initialCustomizeJiraIssueEnabled: {
      type: Boolean,
      required: false,
      default: false,
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
      projectKeys: this.initialProjectKeys,
    };
  },
  computed: {
    ...mapGetters(['isInheriting']),

    checkboxDisabled() {
      return !this.showJiraIssuesIntegration || this.isInheriting;
    },
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
        {{ s__('JiraService|View Jira issues') }}
        <template #help>
          {{
            s__(
              'JiraService|Warning: All users with access to this GitLab project can view all issues from the Jira project you specify.',
            )
          }}
        </template>
      </gl-form-checkbox>
    </template>

    <div v-if="enableJiraIssues" class="gl-mt-3 gl-pl-6">
      <gl-form-group
        v-if="!isIssueCreation"
        :label="s__('JiraService|Jira project keys')"
        label-for="service_project_keys"
        :description="
          s__(
            'JiraService|Comma-separated list of Jira project keys. Leave blank to include all available keys.',
          )
        "
        data-testid="jira-project-keys"
      >
        <gl-form-input
          id="service_project_keys"
          v-model="projectKeys"
          name="service[project_keys]"
          width="xl"
          data-testid="jira-project-keys-field"
          :placeholder="s__('JiraService|AB,CD')"
          :readonly="isInheriting"
        />
      </gl-form-group>
    </div>

    <template v-if="isIssueCreation">
      <jira-issue-creation-vulnerabilities
        :initial-is-enabled="initialEnableJiraVulnerabilities"
        :initial-project-key="initialProjectKey"
        :initial-issue-type-id="initialVulnerabilitiesIssuetype"
        :initial-customize-jira-issue-enabled="initialCustomizeJiraIssueEnabled"
        :is-validated="isValidated"
        :show-full-feature="showJiraVulnerabilitiesIntegration"
        class="gl-mt-6"
        data-testid="jira-for-vulnerabilities"
        @request-jira-issue-types="$emit('request-jira-issue-types')"
      />
    </template>
  </div>
</template>
