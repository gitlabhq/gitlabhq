/* global Vue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.RemoveIssueBtn = Vue.extend({
    props: {
      issue: {
        type: Object,
        required: true,
      },
      list: {
        type: Object,
        required: true,
      },
    },
    methods: {
      removeIssue() {
        const lists = this.issue.getLists();
        const labelIds = lists.map(list => list.label.id);

        // Post the remove data
        gl.boardService.bulkUpdate([this.issue.globalId], {
          remove_label_ids: labelIds,
        });

        // Remove from the frontend store
        lists.forEach((list) => {
          list.removeIssue(this.issue);
        });

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
