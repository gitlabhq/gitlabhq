import Vue from 'vue';
import Flash from '../../../flash';
import { __ } from '../../../locale';

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
  computed: {
    updateUrl() {
      return this.issue.path;
    },
  },
  methods: {
    removeIssue() {
      const board = Store.state.currentBoard;
      const issue = this.issue;
      const lists = issue.getLists();
      const boardLabelIds = board.labels.map(label => label.id);
      const listLabelIds = lists.map(list => list.label.id);

      let labelIds = issue.labels
        .map(label => label.id)
        .filter(id => !listLabelIds.includes(id))
        .filter(id => !boardLabelIds.includes(id));
      if (labelIds.length === 0) {
        labelIds = [''];
      }

      let assigneeIds = issue.assignees
        .map(assignee => assignee.id)
        .filter(id => id !== board.assignee.id);
      if (assigneeIds.length === 0) {
        // for backend to explicitly set No Assignee
        assigneeIds = ['0'];
      }

      const data = {
        issue: {
          label_ids: labelIds,
          assignee_ids: assigneeIds,
        },
      };

      if (board.milestone_id) {
        data.issue.milestone_id = -1;
      }

      if (board.weight) {
        data.issue.weight = null;
      }

      // Post the remove data
      Vue.http.patch(this.updateUrl, data).catch(() => {
        Flash(__('Failed to remove issue from board, please try again.'));

        lists.forEach((list) => {
          list.addIssue(issue);
        });
      });

      // Remove from the frontend store
      lists.forEach((list) => {
        list.removeIssue(issue);
      });

      Store.detail.issue = {};
    },
  },
  template: `
    <div
      class="block list">
      <button
        class="btn btn-default btn-block"
        type="button"
        @click="removeIssue">
        Remove from board
      </button>
    </div>
  `,
});
