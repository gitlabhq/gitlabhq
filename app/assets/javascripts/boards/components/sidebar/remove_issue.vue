<script>
import axios from '~/lib/utils/axios_utils';
import Flash from '../../../flash';
import { __ } from '../../../locale';
import boardsStore from '../../stores/boards_store';

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
      const req = this.buildPatchRequest(issue, lists);

      const data = {
        issue: this.seedPatchRequest(issue, req),
      };

      if (data.issue.label_ids.length === 0) {
        data.issue.label_ids = [''];
      }

      // Post the remove data
      axios.patch(this.updateUrl, data).catch(() => {
        Flash(__('Failed to remove issue from board, please try again.'));

        lists.forEach(list => {
          list.addIssue(issue);
        });
      });

      // Remove from the frontend store
      lists.forEach(list => {
        list.removeIssue(issue);
      });

      boardsStore.clearDetailIssue();
    },
    /**
     * Build the default patch request.
     */
    buildPatchRequest(issue, lists) {
      const listLabelIds = lists.map(list => list.label.id);

      const labelIds = issue.labels.map(label => label.id).filter(id => !listLabelIds.includes(id));

      return {
        label_ids: labelIds,
      };
    },
    /**
     * Seed the given patch request.
     *
     * (This is overridden in EE)
     */
    seedPatchRequest(issue, req) {
      return req;
    },
  },
};
</script>
<template>
  <div class="block list">
    <button class="btn btn-default btn-block" type="button" @click="removeIssue">
      {{ __('Remove from board') }}
    </button>
  </div>
</template>
