<script>
import { GlFormGroup, GlFormCheckbox, GlFormInput, GlSprintf, GlLink } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import eventHub from '../event_hub';
import JiraUpgradeCta from './jira_upgrade_cta.vue';

export default {
  name: 'JiraIssuesFields',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
    GlSprintf,
    GlLink,
    JiraUpgradeCta,
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
    gitlabIssuesEnabled: {
      type: Boolean,
      required: false,
      default: true,
    },
    upgradePlanPath: {
      type: String,
      required: false,
      default: '',
    },
    editProjectPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      enableJiraIssues: this.initialEnableJiraIssues,
      projectKey: this.initialProjectKey,
      validated: false,
    };
  },
  computed: {
    ...mapGetters(['isInheriting']),
    validProjectKey() {
      return !this.enableJiraIssues || Boolean(this.projectKey) || !this.validated;
    },
  },
  created() {
    eventHub.$on('validateForm', this.validateForm);
  },
  beforeDestroy() {
    eventHub.$off('validateForm', this.validateForm);
  },
  methods: {
    validateForm() {
      this.validated = true;
    },
    getJiraIssueTypes() {
      eventHub.$emit('getJiraIssueTypes');
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="s__('JiraService|View Jira issues in GitLab')"
      label-for="jira-issue-settings"
    >
      <div id="jira-issue-settings">
        <p>
          {{
            s__(
              'JiraService|Work on Jira issues without leaving GitLab. Adds a Jira menu to access your list of Jira issues and view any issue as read-only.',
            )
          }}
        </p>
        <template v-if="showJiraIssuesIntegration">
          <input name="service[issues_enabled]" type="hidden" :value="enableJiraIssues || false" />
          <gl-form-checkbox v-model="enableJiraIssues" :disabled="isInheriting">
            {{ s__('JiraService|Enable Jira issues') }}
            <template #help>
              {{
                s__(
                  'JiraService|Warning: All GitLab users that have access to this GitLab project are able to view all issues from the Jira project specified below.',
                )
              }}
            </template>
          </gl-form-checkbox>
          <template v-if="enableJiraIssues">
            <jira-issue-creation-vulnerabilities
              :project-key="projectKey"
              :initial-is-enabled="initialEnableJiraVulnerabilities"
              :initial-issue-type-id="initialVulnerabilitiesIssuetype"
              :show-full-feature="showJiraVulnerabilitiesIntegration"
              data-testid="jira-for-vulnerabilities"
              @request-get-issue-types="getJiraIssueTypes"
            />
            <jira-upgrade-cta
              v-if="!showJiraVulnerabilitiesIntegration"
              class="gl-mt-2 gl-ml-6"
              data-testid="ultimate-upgrade-cta"
              show-ultimate-message
              :upgrade-plan-path="upgradePlanPath"
            />
          </template>
        </template>
        <jira-upgrade-cta
          v-else
          class="gl-mt-2"
          data-testid="premium-upgrade-cta"
          show-premium-message
          :upgrade-plan-path="upgradePlanPath"
        />
      </div>
    </gl-form-group>
    <template v-if="showJiraIssuesIntegration">
      <gl-form-group
        :label="s__('JiraService|Jira project key')"
        label-for="service_project_key"
        :invalid-feedback="__('This field is required.')"
        :state="validProjectKey"
      >
        <gl-form-input
          id="service_project_key"
          v-model="projectKey"
          name="service[project_key]"
          :placeholder="s__('JiraService|For example, AB')"
          :required="enableJiraIssues"
          :state="validProjectKey"
          :disabled="!enableJiraIssues"
          :readonly="isInheriting"
        />
      </gl-form-group>
      <p v-if="gitlabIssuesEnabled">
        <gl-sprintf
          :message="
            s__(
              'JiraService|Displaying Jira issues while leaving the GitLab issue functionality enabled might be confusing. Consider %{linkStart}disabling GitLab issues%{linkEnd} if they won’t otherwise be used.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="editProjectPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
  </div>
</template>
