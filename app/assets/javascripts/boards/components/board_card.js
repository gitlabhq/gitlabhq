/* eslint-disable comma-dangle, space-before-function-paren, dot-notation */
/* global Vue */

require('./issue_card_inner');

(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardCard = Vue.extend({
    template: '#js-board-list-card',
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
    data () {
      return {
        showDetail: false,
        detailIssue: Store.detail
      };
    },
    computed: {
      issueDetailVisible () {
        return this.detailIssue.issue && this.detailIssue.issue.id === this.issue.id;
      }
    },
    methods: {
      mouseDown () {
        this.showDetail = true;
      },
      mouseMove() {
        this.showDetail = false;
      },
      showIssue (e) {
        const targetTagName = e.target.tagName.toLowerCase();

        if (targetTagName === 'a' || targetTagName === 'button') return;

        if (this.showDetail) {
          this.showDetail = false;

          if (Store.detail.issue && Store.detail.issue.id === this.issue.id) {
            Store.detail.issue = {};
          } else {
            Store.detail.issue = this.issue;
            Store.detail.list = this.list;
          }
        }
      }
    }
  });
})();
