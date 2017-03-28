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
    <div style="display:flex">
      <i class="fa fa-eye-slash confidential-icon" v-if="issue.confidential"></i>
      <h4 class="card-title">
        <a style="color: rgba(0,0,0,.85);"
          :href="issueLinkBase + '/' + issue.id"
          :title="issue.title">
          {{ issue.title }}
        </a>
      </h4>
      <span style="margin-left:5px;font-size: 12px;color: rgba(0,0,0,.55);"
        v-if="issue.id">
        #{{ issue.id }}
      </span>
      <a style="margin-left:auto;padding-left:10px;"
        class="card-assignee has-tooltip"
        :href="rootPath + issue.assignee.username"
        :title="'Assigned to ' + issue.assignee.name"
        v-if="issue.assignee"
        data-container="body">
        <img style="margin:0"
          class="avatar avatar-inline s20"
          :src="issue.assignee.avatar"
          width="20"
          height="20"
          :alt="'Avatar for ' + issue.assignee.name" />
      </a>
    </div>
  `,
};
