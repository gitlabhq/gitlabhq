import Vue from 'vue';
import Flash from '../../../flash';
import { __ } from '../../../locale';
import './lists_dropdown';
import { pluralize } from '../../../lib/utils/text_utility';
import ModalStore from '../../stores/modal_store';
import modalMixin from '../../mixins/modal_mixins';

gl.issueBoards.ModalFooter = Vue.extend({
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
    addIssues() {
      const firstListIndex = 1;
      const list = this.modal.selectedList || this.state.lists[firstListIndex];
      const selectedIssues = ModalStore.getSelectedIssues();
      const issueIds = selectedIssues.map(issue => issue.id);
      const currentBoard = this.state.currentBoard;
      const boardLabelIds = currentBoard.labels.map(label => label.id);
      const assigneeIds = currentBoard.assignee && [currentBoard.assignee.id];

      // Post the data to the backend
      gl.boardService.bulkUpdate(issueIds, {
        add_label_ids: [list.label.id, ...boardLabelIds],
        milestone_id: currentBoard.milestone_id,
        assignee_ids: assigneeIds,
        weight: currentBoard.weight,
      }).catch(() => {
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
  components: {
    'lists-dropdown': gl.issueBoards.ModalFooterListsDropdown,
  },
  template: `
    <footer
      class="form-actions add-issues-footer">
      <div class="pull-left">
        <button
          class="btn btn-success"
          type="button"
          :disabled="submitDisabled"
          @click="addIssues">
          {{ submitText }}
        </button>
        <span class="inline add-issues-footer-to-list">
          to list
        </span>
        <lists-dropdown></lists-dropdown>
      </div>
      <button
        class="btn btn-default pull-right"
        type="button"
        @click="toggleModal(false)">
        Cancel
      </button>
    </footer>
  `,
});
