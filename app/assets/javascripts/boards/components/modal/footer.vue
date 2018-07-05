<script>
import Flash from '../../../flash';
import { __ } from '../../../locale';
import ListsDropdown from './lists_dropdown.vue';
import { pluralize } from '../../../lib/utils/text_utility';
import ModalStore from '../../stores/modal_store';
import modalMixin from '../../mixins/modal_mixins';

export default {
  components: {
    ListsDropdown,
  },
  mixins: [modalMixin],
  data() {
    return {
      modal: ModalStore.store,
      state: gl.issueBoards.BoardsStore.state,
    };
  },
  computed: {
    submitDisabled() {
      return !ModalStore.selectedCount();
    },
    submitText() {
      const count = ModalStore.selectedCount();

      return `Add ${count > 0 ? count : ''} ${pluralize('issue', count)}`;
    },
  },
  methods: {
    buildUpdateRequest(list) {
      return {
        add_label_ids: [list.label.id],
      };
    },
    addIssues() {
      const firstListIndex = 1;
      const list = this.modal.selectedList || this.state.lists[firstListIndex];
      const selectedIssues = ModalStore.getSelectedIssues();
      const issueIds = selectedIssues.map(issue => issue.id);
      const req = this.buildUpdateRequest(list);

      // Post the data to the backend
      gl.boardService
        .bulkUpdate(issueIds, req)
        .catch(() => {
          Flash(__('Failed to update issues, please try again.'));

          selectedIssues.forEach((issue) => {
            list.removeIssue(issue);
            list.issuesSize -= 1;
          });
        });

      // Add the issues on the frontend
      selectedIssues.forEach((issue) => {
        list.addIssue(issue);
        list.issuesSize += 1;
      });

      this.toggleModal(false);
    },
  },
};
</script>
<template>
  <footer
    class="form-actions add-issues-footer"
  >
    <div class="float-left">
      <button
        :disabled="submitDisabled"
        class="btn btn-success"
        type="button"
        @click="addIssues"
      >
        {{ submitText }}
      </button>
      <span class="inline add-issues-footer-to-list">
        to list
      </span>
      <lists-dropdown/>
    </div>
    <button
      class="btn btn-default float-right"
      type="button"
      @click="toggleModal(false)"
    >
      Cancel
    </button>
  </footer>
</template>
