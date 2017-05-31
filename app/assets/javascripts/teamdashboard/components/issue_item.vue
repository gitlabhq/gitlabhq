<script>
export default {
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  methods: {
    issueClass(state) {
      return `issuable-row issue-block issue-state issue-state-${state}`;
    },
    showLabel(label) {
      return true;
    },
    labelStyle(label) {
      return {
        backgroundColor: label.color,
        color: label.textColor,
      };
    },
  }
}
</script>
<template>
  <li :class="issueClass(issue.state)" data-id="4057910" data-iid="27164" data-url="/gitlab-org/gitlab-ce/issues/27164" id="sortable_issue_4057910">
          <span>
            <i
              class="fa fa-eye-slash confidential-icon"
              v-if="issue.confidential"
              aria-hidden="true"
            />
            <a
              class="js-no-trigger"
              :href="issue.web_url"
              :title="issue.title">{{ issue.title }}</a>

            <span v-if="issue.weight">
              <i aria-hidden="true" class="fa fa-balance-scale"></i> {{issue.weight}} 
            </span>
          </span>
          <div class="issuable-detail">
          <a href="/gitlab-org/gitlab-ce/issues/27164"><span class="issuable-number">#27164</span></a>
          <a href="/gitlab-org/gitlab-ce/issues?label_name=backend&amp;milestone_title=9.3&amp;state=all">
            <span
              class="label color-label has-tooltip"
              style="background-color:#666"
              v-for="label in issue.labels"
              v-if="showLabel(label)" 
              :style="labelStyle(label)"
              :title="label.description">
              {{ label }}
            </span>
          </a>
          <span class="assignee-icon">
          </span>
          </div>
  </li>
</template>
