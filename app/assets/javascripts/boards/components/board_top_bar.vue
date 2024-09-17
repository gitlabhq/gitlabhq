<script>
import { s__ } from '~/locale';
import BoardsSelector from 'ee_else_ce/boards/components/boards_selector.vue';
import IssueBoardFilteredSearch from 'ee_else_ce/boards/components/issue_board_filtered_search.vue';
import { getBoardQuery } from 'ee_else_ce/boards/boards_util';
import { setError } from '../graphql/cache_updates';
import ConfigToggle from './config_toggle.vue';
import ToggleFocus from './toggle_focus.vue';
import BoardOptions from './board_options.vue';

export default {
  components: {
    BoardOptions,
    BoardsSelector,
    IssueBoardFilteredSearch,
    ConfigToggle,
    ToggleFocus,
    EpicBoardFilteredSearch: () =>
      import('ee_component/boards/components/epic_filtered_search.vue'),
  },
  inject: [
    'swimlanesFeatureAvailable',
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
      class="issues-details-filters filtered-search-block row-content-block second-block gl-flex gl-flex-col gl-gap-3 gl-px-5 md:gl-flex-row xl:gl-px-6"
    >
      <div class="gl-mb-0 gl-flex gl-w-full gl-min-w-0 gl-grow gl-flex-col gl-gap-3 md:gl-flex-row">
        <div class="gl-flex gl-items-center gl-gap-3 md:gl-mb-0">
          <boards-selector
            :board="board"
            :is-current-board-loading="isLoading"
            :board-modal-form="currentForm"
            class="gl-flex-grow"
            @switchBoard="$emit('switchBoard', $event)"
            @updateBoard="$emit('updateBoard', $event)"
            @showBoardModal="setCurrentForm"
          />
          <div class="gl-flex gl-items-center gl-gap-2 md:!gl-hidden">
            <board-options
              :show-epic-lane-option="swimlanesFeatureAvailable && isSignedIn"
              :is-swimlanes-on="isSwimlanesOn"
              @toggleSwimlanes="$emit('toggleSwimlanes', $event)"
            />
            <config-toggle @showBoardModal="setCurrentForm" />
          </div>
        </div>

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
      <div class="gl-hidden gl-gap-2 md:gl-flex">
        <board-options
          :show-epic-lane-option="swimlanesFeatureAvailable && isSignedIn"
          :is-swimlanes-on="isSwimlanesOn"
          @toggleSwimlanes="$emit('toggleSwimlanes', $event)"
        />
        <config-toggle @showBoardModal="setCurrentForm" />

        <toggle-focus />
      </div>
    </div>
  </div>
</template>
