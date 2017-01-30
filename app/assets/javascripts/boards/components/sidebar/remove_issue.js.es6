/* global Vue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.RemoveIssueBtn = Vue.extend({
    props: [
      'issue', 'list',
    ],
    methods: {
      removeIssue() {
        const doneList = Store.findList('type', 'done', false);

        Store.moveIssueToList(this.list, doneList, this.issue, 0);

        Store.detail.issue = {};
      },
    },
    template: `
      <div
        class="block list"
        v-if="list.type !== 'done'">
        <button
          class="btn btn-default btn-block"
          type="button"
          @click="removeIssue">
          Remove from board
        </button>
      </div>
    `,
  });
})();
