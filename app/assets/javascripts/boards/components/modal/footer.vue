<script>
import { GlButton } from '@gitlab/ui';
import footerEEMixin from 'ee_else_ce/boards/mixins/modal_footer';
import { deprecatedCreateFlash as Flash } from '../../../flash';
import { __, n__ } from '../../../locale';
import ListsDropdown from './lists_dropdown.vue';
import ModalStore from '../../stores/modal_store';
import modalMixin from '../../mixins/modal_mixins';
import boardsStore from '../../stores/boards_store';

export default {
  components: {
    ListsDropdown,
    GlButton,
  },
  mixins: [modalMixin, footerEEMixin],
  data() {
    return {
      modal: ModalStore.store,
      state: boardsStore.state,
    };
  },
  computed: {
    submitDisabled() {
      return !ModalStore.selectedCount();
    },
    submitText() {
      const count = ModalStore.selectedCount();
      if (!count) return __('Add issues');
      return n__(`Add %d issue`, `Add %d issues`, count);
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
      boardsStore.bulkUpdate(issueIds, req).catch(() => {
        Flash(__('Failed to update issues, please try again.'));

        selectedIssues.forEach(issue => {
          list.removeIssue(issue);
          list.issuesSize -= 1;
        });
      });

      // Add the issues on the frontend
      selectedIssues.forEach(issue => {
        list.addIssue(issue);
        list.issuesSize += 1;
      });

      this.toggleModal(false);
    },
  },
};
</script>
<template>
  <footer class="form-actions add-issues-footer">
    <div class="float-left">
      <gl-button :disabled="submitDisabled" category="primary" variant="success" @click="addIssues">
        {{ submitText }}
      </gl-button>
      <span class="inline add-issues-footer-to-list">{{ __('to list') }}</span>
      <lists-dropdown />
    </div>
    <gl-button class="float-right" @click="toggleModal(false)">
      {{ __('Cancel') }}
    </gl-button>
  </footer>
</template>
