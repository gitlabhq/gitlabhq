export default {
  name: 'IssueCardHeader',
  props: {
    confidential: { type: Boolean, required: true },
    title: { type: String, required: true },
    issueId: { type: Number, required: true },
    assignee: { type: Object, required: true },
    issueLinkBase: { type: String, required: true },
    rootPath: { type: String, required: true },
  },
  computed: {
    hasAssignee() {
      return Object.keys(this.assignee).length > 0;
    },
  },
  template: `
    <div class="card-header">
      <i class="fa fa-eye-slash confidential-icon"
        v-if="confidential">
      </i>
      <h4 class="card-title">
        <a :href="issueLinkBase + '/' + issueId"
          :title="title">{{ title }}</a>
        <span class="card-number">#{{ issueId }}</span>
      </h4>
      <a class="card-assignee has-tooltip"
        :href="rootPath + assignee.username"
        :title="'Assigned to ' + assignee.name"
        v-if="hasAssignee"
        data-container="body">
        <img class="avatar avatar-inline s20"
          :src="assignee.avatar"
          width="20"
          height="20"
          :alt="'Avatar for ' + assignee.name" />
      </a>
    </div>
  `,
};
