<script>
  import Vue from 'vue';
  import Flash from '../../../flash';
  import { __ } from '../../../locale';

  const Store = gl.issueBoards.BoardsStore;

  export default {
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
        const { issue } = this;
        const lists = issue.getLists();
        const listLabelIds = lists.map(list => list.label.id);

        let labelIds = issue.labels.map(label => label.id).filter(id => !listLabelIds.includes(id));
        if (labelIds.length === 0) {
          labelIds = [''];
        }

        const data = {
          issue: {
            label_ids: labelIds,
          },
        };

        // Post the remove data
        Vue.http.patch(this.updateUrl, data).catch(() => {
          Flash(__('Failed to remove issue from board, please try again.'));

          lists.forEach(list => {
            list.addIssue(issue);
          });
        });

        // Remove from the frontend store
        lists.forEach(list => {
          list.removeIssue(issue);
        });

        Store.detail.issue = {};
      },
    },
  };
</script>
<template>
  <div
    class="block list"
  >
    <button
      class="btn btn-default btn-block"
      type="button"
      @click="removeIssue"
    >
      Remove from board
    </button>
  </div>
</template>
