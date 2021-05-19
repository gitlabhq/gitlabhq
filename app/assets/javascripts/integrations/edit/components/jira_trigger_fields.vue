<script>
import {
  GlFormGroup,
  GlFormCheckbox,
  GlFormRadio,
  GlFormInput,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

const commentDetailOptions = [
  {
    value: 'standard',
    label: s__('Integrations|Standard'),
    help: s__('Integrations|Includes commit title and branch.'),
  },
  {
    value: 'all_details',
    label: s__('Integrations|All details'),
    help: s__(
      'Integrations|Includes Standard, plus the entire commit message, commit hash, and issue IDs',
    ),
  },
];

const ISSUE_TRANSITION_AUTO = true;
const ISSUE_TRANSITION_CUSTOM = false;

const issueTransitionOptions = [
  {
    value: ISSUE_TRANSITION_AUTO,
    label: s__('JiraService|Move to Done'),
    help: s__(
      'JiraService|Automatically transitions Jira issues to the "Done" category. %{linkStart}Learn more%{linkEnd}',
    ),
    link: helpPagePath('integration/jira/index.html', {
      anchor: 'automatic-issue-transitions',
    }),
  },
  {
    value: ISSUE_TRANSITION_CUSTOM,
    label: s__('JiraService|Use custom transitions'),
    help: s__(
      'JiraService|Set a custom final state by using transition IDs. %{linkStart}Learn about transition IDs%{linkEnd}',
    ),
    link: helpPagePath('integration/jira/index.html', {
      anchor: 'custom-issue-transitions',
    }),
  },
];

export default {
  name: 'JiraTriggerFields',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormRadio,
    GlFormInput,
    GlLink,
    GlSprintf,
  },
  props: {
    initialTriggerCommit: {
      type: Boolean,
      required: true,
    },
    initialTriggerMergeRequest: {
      type: Boolean,
      required: true,
    },
    initialEnableComments: {
      type: Boolean,
      required: true,
    },
    initialCommentDetail: {
      type: String,
      required: false,
      default: 'standard',
    },
    initialJiraIssueTransitionAutomatic: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialJiraIssueTransitionId: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      validated: false,
      triggerCommit: this.initialTriggerCommit,
      triggerMergeRequest: this.initialTriggerMergeRequest,
      enableComments: this.initialEnableComments,
      commentDetail: this.initialCommentDetail,
      jiraIssueTransitionAutomatic:
        this.initialJiraIssueTransitionAutomatic || !this.initialJiraIssueTransitionId,
      jiraIssueTransitionId: this.initialJiraIssueTransitionId,
      issueTransitionEnabled:
        this.initialJiraIssueTransitionAutomatic || Boolean(this.initialJiraIssueTransitionId),
      commentDetailOptions,
      issueTransitionOptions,
    };
  },
  computed: {
    ...mapGetters(['isInheriting']),
    showTriggerSettings() {
      return this.triggerCommit || this.triggerMergeRequest;
    },
    validIssueTransitionId() {
      return !this.validated || Boolean(this.jiraIssueTransitionId);
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
    showCustomIssueTransitions(currentOption) {
      return (
        this.jiraIssueTransitionAutomatic === ISSUE_TRANSITION_CUSTOM &&
        currentOption === ISSUE_TRANSITION_CUSTOM
      );
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="__('Trigger')"
      label-for="service[trigger]"
      :description="
        s__(
          'Integrations|When you mention a Jira issue in a commit or merge request, GitLab creates a remote link and comment (if enabled).',
        )
      "
    >
      <input name="service[commit_events]" type="hidden" :value="triggerCommit || false" />
      <gl-form-checkbox v-model="triggerCommit" :disabled="isInheriting">
        {{ __('Commit') }}
      </gl-form-checkbox>

      <input
        name="service[merge_requests_events]"
        type="hidden"
        :value="triggerMergeRequest || false"
      />
      <gl-form-checkbox v-model="triggerMergeRequest" :disabled="isInheriting">
        {{ __('Merge request') }}
      </gl-form-checkbox>
    </gl-form-group>

    <gl-form-group
      v-show="showTriggerSettings"
      :label="s__('Integrations|Comment settings:')"
      label-for="service[comment_on_event_enabled]"
      class="gl-pl-6"
      data-testid="comment-settings"
    >
      <input
        name="service[comment_on_event_enabled]"
        type="hidden"
        :value="enableComments || false"
      />
      <gl-form-checkbox v-model="enableComments" :disabled="isInheriting">
        {{ s__('Integrations|Enable comments') }}
      </gl-form-checkbox>
    </gl-form-group>

    <gl-form-group
      v-show="showTriggerSettings && enableComments"
      :label="s__('Integrations|Comment detail:')"
      label-for="service[comment_detail]"
      class="gl-pl-9"
      data-testid="comment-detail"
    >
      <input name="service[comment_detail]" type="hidden" :value="commentDetail" />
      <gl-form-radio
        v-for="commentDetailOption in commentDetailOptions"
        :key="commentDetailOption.value"
        v-model="commentDetail"
        :value="commentDetailOption.value"
        :disabled="isInheriting"
      >
        {{ commentDetailOption.label }}
        <template #help>
          {{ commentDetailOption.help }}
        </template>
      </gl-form-radio>
    </gl-form-group>

    <gl-form-group
      v-if="showTriggerSettings"
      :label="s__('JiraService|Transition Jira issues to their final state:')"
      class="gl-pl-6"
      data-testid="issue-transition-enabled"
    >
      <input type="hidden" name="service[jira_issue_transition_automatic]" value="false" />
      <input type="hidden" name="service[jira_issue_transition_id]" value="" />

      <gl-form-checkbox
        v-model="issueTransitionEnabled"
        :disabled="isInheriting"
        data-qa-selector="service_jira_issue_transition_enabled_checkbox"
      >
        {{ s__('JiraService|Enable Jira transitions') }}
      </gl-form-checkbox>
    </gl-form-group>

    <gl-form-group
      v-if="showTriggerSettings && issueTransitionEnabled"
      class="gl-pl-9"
      data-testid="issue-transition-mode"
    >
      <gl-form-radio
        v-for="issueTransitionOption in issueTransitionOptions"
        :key="issueTransitionOption.value"
        v-model="jiraIssueTransitionAutomatic"
        name="service[jira_issue_transition_automatic]"
        :value="issueTransitionOption.value"
        :disabled="isInheriting"
        :data-qa-selector="`service_jira_issue_transition_automatic_${issueTransitionOption.value}_radio`"
      >
        {{ issueTransitionOption.label }}

        <template v-if="showCustomIssueTransitions(issueTransitionOption.value)">
          <gl-form-input
            v-model="jiraIssueTransitionId"
            name="service[jira_issue_transition_id]"
            type="text"
            class="gl-my-3"
            data-qa-selector="service_jira_issue_transition_id_field"
            :placeholder="s__('JiraService|For example, 12, 24')"
            :disabled="isInheriting"
            :required="true"
            :state="validIssueTransitionId"
          />

          <span class="invalid-feedback">
            {{ __('This field is required.') }}
          </span>
        </template>

        <template #help>
          <gl-sprintf :message="issueTransitionOption.help">
            <template #link="{ content }">
              <gl-link :href="issueTransitionOption.link" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
      </gl-form-radio>
    </gl-form-group>
  </div>
</template>
