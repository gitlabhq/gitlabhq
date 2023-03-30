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
    isSwimlanesOn: {
      type: Boolean,
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
        const { board } = data.workspace;
        return {
          ...board,
          labels: board.labels?.nodes,
        };
      },
    },
  },
  computed: {
    hasScope() {
      if (this.board.labels?.length > 0) {
        return true;
      }
      let hasScope = false;
      ['assignee', 'iterationCadence', 'iteration', 'milestone', 'weight'].forEach((attr) => {
        if (this.board[attr] !== null && this.board[attr] !== undefined) {
          hasScope = true;
        }
      });
      return hasScope;
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
        <issue-board-filtered-search
          v-if="isIssueBoard"
          :board="board"
          :is-swimlanes-on="isSwimlanesOn"
          @setFilters="$emit('setFilters', $event)"
        />
        <epic-board-filtered-search
          v-else
          :board="board"
          @setFilters="$emit('setFilters', $event)"
        />
      </div>
      <div
        class="filter-dropdown-container gl-md-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-align-items-flex-start"
      >
        <toggle-labels />
        <toggle-epics-swimlanes
          v-if="swimlanesFeatureAvailable && isSignedIn"
          :is-swimlanes-on="isSwimlanesOn"
          @toggleSwimlanes="$emit('toggleSwimlanes', $event)"
        />
        <config-toggle :board-has-scope="hasScope" />
        <board-add-new-column-trigger v-if="canAdminList" />
        <toggle-focus />
      </div>
    </div>
  </div>
</template>
