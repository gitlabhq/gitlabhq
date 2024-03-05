<script>
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import { s__ } from '~/locale';
import BoardsSelector from 'ee_else_ce/boards/components/boards_selector.vue';
import IssueBoardFilteredSearch from 'ee_else_ce/boards/components/issue_board_filtered_search.vue';
import { getBoardQuery } from 'ee_else_ce/boards/boards_util';
import ToggleLabels from '~/vue_shared/components/toggle_labels.vue';
import { setError } from '../graphql/cache_updates';
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
    ToggleLabels,
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
  ],
  props: {
    boardId: {
      type: String,
      required: true,
    },
    addColumnFormVisible: {
      type: Boolean,
      required: true,
    },
    isSwimlanesOn: {
      type: Boolean,
      required: true,
    },
    filters: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      board: {},
      currentForm: '',
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
      update(data) {
        const { board } = data.workspace;
        return {
          ...board,
          labels: board.labels?.nodes,
        };
      },
      error(error) {
        setError({
          error,
          message: s__('Boards|An error occurred while fetching board details. Please try again.'),
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.board.loading;
    },
  },
  methods: {
    setCurrentForm(formType) {
      this.currentForm = formType;
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
        class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-flex-grow-1 gl-lg-mb-0 gl-mb-3 gl-w-full gl-min-w-0"
      >
        <boards-selector
          :board="board"
          :is-current-board-loading="isLoading"
          :board-modal-form="currentForm"
          @switchBoard="$emit('switchBoard', $event)"
          @updateBoard="$emit('updateBoard', $event)"
          @showBoardModal="setCurrentForm"
        />
        <new-board-button @showBoardModal="setCurrentForm" />
        <issue-board-filtered-search
          v-if="isIssueBoard"
          :board="board"
          :is-swimlanes-on="isSwimlanesOn"
          :filters="filters"
          @setFilters="$emit('setFilters', $event)"
        />
        <epic-board-filtered-search
          v-else
          :board="board"
          :filters="filters"
          @setFilters="$emit('setFilters', $event)"
        />
      </div>
      <div
        class="filter-dropdown-container gl-md-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-align-items-flex-start"
      >
        <div
          class="gl-display-flex gl-flex-direction-row gl-sm-align-items-flex-start gl-xs-justify-content-end gl-flex-wrap gl-md-flex-nowrap"
        >
          <toggle-labels />
          <toggle-epics-swimlanes
            v-if="swimlanesFeatureAvailable && isSignedIn"
            :is-swimlanes-on="isSwimlanesOn"
            @toggleSwimlanes="$emit('toggleSwimlanes', $event)"
          />
        </div>
        <config-toggle @showBoardModal="setCurrentForm" />
        <board-add-new-column-trigger
          v-if="canAdminList"
          :is-new-list-showing="addColumnFormVisible"
          @setAddColumnFormVisibility="$emit('setAddColumnFormVisibility', $event)"
        />
        <toggle-focus />
      </div>
    </div>
  </div>
</template>
