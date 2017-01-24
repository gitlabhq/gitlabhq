/* global Vue */
/* global ListIssue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.ModalList = Vue.extend({
    data() {
      return Store.modal;
    },
    computed: {
      loading() {
        return this.issues.length === 0;
      },
    },
    mounted() {
      gl.boardService.getBacklog()
        .then((res) => {
          const data = res.json();

          data.forEach((issueObj) => {
            this.issues.push(new ListIssue(issueObj));
          });
        });
    },
    components: {
      'issue-card-inner': gl.issueBoards.IssueCardInner,
    },
    template: `
      <section class="add-issues-list">
        <i
          class="fa fa-spinner fa-spin"
          v-if="loading"></i>
        <ul
          class="add-issues-list-columns list-unstyled"
          v-if="!loading">
          <li
            class="card"
            v-for="issue in issues">
            <issue-card-inner
              :issue="issue"
              :issue-link-base="'/'">
            </issue-card-inner>
          </li>
        </ul>
      </section>
    `,
  });
})();
