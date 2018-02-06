/* eslint-disable no-new */

import Vue from 'vue';
import Flash from '../../../flash';

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
    issueUpdate: {
      type: String,
      required: true,
    },
  },
  computed: {
    updateUrl() {
      return this.issueUpdate;
    },
  },
  methods: {
    removeIssue() {
      const issue = this.issue;
      const lists = issue.getLists();
      const listLabelIds = lists.map(list => list.label.id);
      let labelIds = this.issue.labels
        .map(label => label.id)
        .filter(id => !listLabelIds.includes(id));
      if (labelIds.length === 0) {
        labelIds = [''];
      }
      const data = {
        issue: {
          label_ids: labelIds,
        },
      };
      Vue.http.patch(this.updateUrl, data).catch(() => {
        new Flash('Failed to remove issue from board, please try again.', 'alert');

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
