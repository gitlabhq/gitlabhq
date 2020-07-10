<script>
import { GlFormGroup, GlFormCheckbox, GlFormInput, GlSprintf, GlLink } from '@gitlab/ui';

export default {
  name: 'JiraIssuesFields',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
    GlSprintf,
    GlLink,
  },
  props: {
    initialEnableJiraIssues: {
      type: Boolean,
      required: false,
    },
    initialProjectKey: {
      type: String,
      required: false,
      default: null,
    },
    editProjectPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      enableJiraIssues: this.initialEnableJiraIssues,
      projectKey: this.initialProjectKey,
    };
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
              'JiraService|Work on Jira issues without leaving GitLab. Adds a Jira menu to access your list of issues and view any issue as read-only.',
            )
          }}
        </p>
        <input name="service[issues_enabled]" type="hidden" value="false" />
        <gl-form-checkbox v-model="enableJiraIssues" name="service[issues_enabled]">
          {{ s__('JiraService|Enable Jira issues') }}
          <template #help>
            {{
              s__(
                'JiraService|Warning: All GitLab users that have access to this GitLab project will be able to view all issues from the Jira project specified below.',
              )
            }}
          </template>
        </gl-form-checkbox>
      </div>
    </gl-form-group>
    <gl-form-group :label="s__('JiraService|Jira project key')">
      <gl-form-input
        v-model="projectKey"
        type="text"
        name="service[project_key]"
        :placeholder="s__('JiraService|e.g. AB')"
        :disabled="!enableJiraIssues"
      />
    </gl-form-group>
    <p>
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
  </div>
</template>
