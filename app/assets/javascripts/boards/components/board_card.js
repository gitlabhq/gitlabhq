require('./issue_card_inner');

export default {
  name: 'BoardsIssueCard',
  template: `
    <li class="card"
      :class="{ 'user-can-drag': !disabled && issue.id, 'is-disabled': disabled || !issue.id, 'is-active': issueDetailVisible }"
      :index="index"
      :data-issue-id="issue.id"
      @mousedown="mouseDown"
      @mousemove="mouseMove"
      @mouseup="showIssue($event)">
      <issue-card-inner
        :list="list"
        :issue="issue"
        :issue-link-base="issueLinkBase"
        :root-path="rootPath"
        :update-filters="true" />
    </li>
  `,
  components: {
    'issue-card-inner': gl.issueBoards.IssueCardInner,
  },
  props: {
    list: Object,
    issue: Object,
    issueLinkBase: String,
    disabled: Boolean,
    index: Number,
    rootPath: String,
  },
  data() {
    return {
      showDetail: false,
      detailIssue: this.store.detail,
    };
  },
  computed: {
    issueDetailVisible() {
      return this.detailIssue.issue && this.detailIssue.issue.id === this.issue.id;
    },
  },
  methods: {
    mouseDown() {
      this.showDetail = true;
    },
    mouseMove() {
      this.showDetail = false;
    },
    showIssue(e) {
      if (e.target.classList.contains('js-no-trigger')) return;

      if (this.showDetail) {
        this.showDetail = false;

        if (this.store.detail.issue && this.store.detail.issue.id === this.issue.id) {
          this.store.detail.issue = {};
        } else {
          this.store.detail.issue = this.issue;
          this.store.detail.list = this.list;
        }
      }
    },
  },
};
