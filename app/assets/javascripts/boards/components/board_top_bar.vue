<script>
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import BoardsSelector from 'ee_else_ce/boards/components/boards_selector.vue';
import IssueBoardFilteredSearch from 'ee_else_ce/boards/components/issue_board_filtered_search.vue';
import { getBoardQuery } from 'ee_else_ce/boards/boards_util';
import ConfigToggle from './config_toggle.vue';
import NewBoardButton from './new_board_button.vue';
import ToggleFocus from './toggle_focus.vue';

export default {
  components: {
    BoardAddNewColumnTrigger,
    BoardsSelector,
    IssueBoardFilteredSearch,
    ConfigToggle,
    NewBoardButton,
    ToggleFocus,
    ToggleLabels: () => import('ee_component/boards/components/toggle_labels.vue'),
    ToggleEpicsSwimlanes: () => import('ee_component/boards/components/toggle_epics_swimlanes.vue'),
    EpicBoardFilteredSearch: () =>
      import('ee_component/boards/components/epic_filtered_search.vue'),
  },
  inject: [
    'swimlanesFeatureAvailable',
    'canAdminList',
    'isSignedIn',
    'isIssueBoard',
    'fullPath',
    'boardType',
    'isEpicBoard',
    'isApolloBoard',
  ],
  props: {
    boardId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      board: {},
    };
  },
  apollo: {
    board: {
      query() {
        return getBoardQuery(this.boardType, this.isEpicBoard);
      },
      variables() {
        return {
          fullPath: this.fullPath,
          boardId: this.boardId,
        };
      },
      skip() {
        return !this.isApolloBoard;
      },
      update(data) {
        return data.workspace.board;
      },
    },
  },
};
</script>

<template>
  <div class="issues-filters">
    <div
      class="issues-details-filters filtered-search-block gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row row-content-block second-block"
    >
      <div
        class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-flex-grow-1 gl-lg-mb-0 gl-mb-3 gl-w-full"
      >
        <boards-selector :board-apollo="board" @switchBoard="$emit('switchBoard', $event)" />
        <new-board-button />
        <issue-board-filtered-search v-if="isIssueBoard" />
        <epic-board-filtered-search v-else />
      </div>
      <div
        class="filter-dropdown-container gl-md-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-align-items-flex-start"
      >
        <toggle-labels />
        <toggle-epics-swimlanes v-if="swimlanesFeatureAvailable && isSignedIn" />
        <config-toggle />
        <board-add-new-column-trigger v-if="canAdminList" />
        <toggle-focus />
      </div>
    </div>
  </div>
</template>
