export default {
  name: 'IssueCardHeader',
  props: {
    issue: { type: Object, required: true },
    issueLinkBase: { type: String, required: true },
    list: { type: Object, required: false },
    rootPath: { type: String, required: true },
    updateFilters: { type: Boolean, required: false, default: false },
  },
  template: `
    <div class="card-header">
      <i class="fa fa-eye-slash confidential-icon"
        v-if="issue.confidential">
      </i>
      <h4 class="card-title">
        <a :href="issueLinkBase + '/' + issue.id"
          :title="issue.title">{{ issue.title.trim() }}</a>
        <span class="card-number"
          v-if="issue.id">
          #{{ issue.id }}
        </span>
      </h4>
      <a class="card-assignee has-tooltip"
        :href="rootPath + issue.assignee.username"
        :title="'Assigned to ' + issue.assignee.name"
        v-if="issue.assignee"
        data-container="body">
        <img class="avatar avatar-inline s20"
          :src="issue.assignee.avatar"
          width="20"
          height="20"
          :alt="'Avatar for ' + issue.assignee.name" />
      </a>
    </div>
  `,
};
