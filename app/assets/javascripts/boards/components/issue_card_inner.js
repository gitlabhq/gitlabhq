import IssueCardHeader from './issue_card_header';
import IssueCardLabels from './issue_card_labels';

export default {
  name: 'IssueCardInner',
  props: {
    issue: { type: Object, required: true },
    issueLinkBase: { type: String, required: true },
    list: { type: Object, required: false },
    rootPath: { type: String, required: true },
    updateFilters: { type: Boolean, required: false, default: false },
  },
  computed: {
    assignee() {
      if (this.issue.assignee === false) {
        return {};
      }

      return this.issue.assignee;
    },
  },
  components: {
    'issue-card-header': IssueCardHeader,
    'issue-card-labels': IssueCardLabels,
  },
  template: `
    <div>
      <issue-card-header
        :confidential="issue.confidential"
        :title="issue.title"
        :issue-id="issue.id"
        :assignee="assignee"
        :issue-link-base="issueLinkBase"
        :root-path="rootPath"/>
      <issue-card-labels
        :labels="issue.labels"
        :list="list"
        :update-filters="true" />
    </div>
  `,
};
