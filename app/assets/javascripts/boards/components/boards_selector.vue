<script>
import { GlButton, GlCollapsibleListbox, GlModalDirective } from '@gitlab/ui';
import { produce } from 'immer';
import { differenceBy, debounce } from 'lodash';

import BoardForm from 'ee_else_ce/boards/components/board_form.vue';

import { formType } from '~/boards/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isModifierKey } from '~/lib/utils/common_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__, __ } from '~/locale';

import groupBoardsQuery from '../graphql/group_boards.query.graphql';
import projectBoardsQuery from '../graphql/project_boards.query.graphql';
import groupRecentBoardsQuery from '../graphql/group_recent_boards.query.graphql';
import projectRecentBoardsQuery from '../graphql/project_recent_boards.query.graphql';
import { setError } from '../graphql/cache_updates';
import { fullBoardId } from '../boards_util';

const MIN_BOARDS_TO_VIEW_RECENT = 10;

export default {
  name: 'BoardsSelector',
  i18n: {
    fetchBoardsError: s__('Boards|An error occurred while fetching boards. Please try again.'),
    headerText: s__('Boards|Switch board'),
    noResultsText: s__('Boards|No matching boards found'),
    hiddenBoardsText: s__(
      'Boards|Some of your boards are hidden, add a license to see them again.',
    ),
  },
  components: {
    BoardForm,
    GlButton,
    GlCollapsibleListbox,
  },
  directives: {
    GlModalDirective,
  },
  inject: [
    'boardBaseUrl',
    'fullPath',
    'canAdminBoard',
    'multipleIssueBoardsAvailable',
    'hasMissingBoards',
    'scopedIssueBoardFeatureEnabled',
    'weights',
    'boardType',
    'isGroupBoard',
  ],
  props: {
    board: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isCurrentBoardLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    boardModalForm: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      boards: [],
      recentBoards: [],
      loadingBoards: false,
      loadingRecentBoards: false,
      contentClientHeight: 0,
      maxPosition: 0,
      filterTerm: '',
    };
  },

  computed: {
    boardName() {
      return this.board?.name || s__('Boards|Select board');
    },
    boardId() {
      return getIdFromGraphQLId(this.board.id) || '';
    },
    parentType() {
      return this.boardType;
    },
    issueBoardsQuery() {
      return this.isGroupBoard ? groupBoardsQuery : projectBoardsQuery;
    },
    boardsQuery() {
      return this.issueBoardsQuery;
    },
    loading() {
      return this.loadingRecentBoards || this.loadingBoards;
    },
    listBoxItems() {
      const mapItems = ({ id, name }) => ({ text: name, value: id });

      if (this.showRecentSection) {
        const notRecent = differenceBy(this.filteredBoards, this.recentBoards, 'id');

        return [
          {
            text: __('Recent'),
            options: this.recentBoards.map(mapItems),
          },
          {
            text: __('All'),
            options: notRecent.map(mapItems),
          },
        ];
      }

      return this.filteredBoards.map(mapItems);
    },
    filteredBoards() {
      return this.boards.filter((board) =>
        board.name.toLowerCase().includes(this.filterTerm.toLowerCase()),
      );
    },
    showCreate() {
      return this.multipleIssueBoardsAvailable;
    },
    isLastBoard() {
      return this.boards.length === 1;
    },
    showDropdown() {
      return this.showCreate || this.hasMissingBoards;
    },
    showRecentSection() {
      return (
        this.recentBoards.length > 0 &&
        this.boards.length > MIN_BOARDS_TO_VIEW_RECENT &&
        !this.filterTerm.length
      );
    },
  },
  watch: {
    board(newBoard) {
      document.title = newBoard.name;
    },
  },
  created() {
    this.handleSearch = debounce(this.setFilterTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  destroyed() {
    this.handleSearch.cancel();
  },
  methods: {
    fullBoardId(boardId) {
      return fullBoardId(boardId);
    },
    cancel() {
      this.$emit('showBoardModal', '');
    },
    boardUpdate(data, boardType) {
      if (!data?.[this.parentType]) {
        return [];
      }
      return data[this.parentType][boardType].nodes.map((node) => ({
        id: getIdFromGraphQLId(node.id),
        name: node.name,
      }));
    },
    recentBoardsQuery() {
      return this.isGroupBoard ? groupRecentBoardsQuery : projectRecentBoardsQuery;
    },
    loadBoards(toggleDropdown = true) {
      if (toggleDropdown && this.boards.length > 0) {
        return;
      }

      this.$apollo.addSmartQuery('boards', {
        variables() {
          return { fullPath: this.fullPath };
        },
        query: this.boardsQuery,
        update: (data) => this.boardUpdate(data, 'boards'),
        watchLoading: (isLoading) => {
          this.loadingBoards = isLoading;
        },
        error(error) {
          setError({
            error,
            message: this.$options.i18n.fetchBoardsError,
          });
        },
      });

      this.loadRecentBoards();
    },
    loadRecentBoards() {
      this.$apollo.addSmartQuery('recentBoards', {
        variables() {
          return { fullPath: this.fullPath };
        },
        query: this.recentBoardsQuery,
        update: (data) => this.boardUpdate(data, 'recentIssueBoards'),
        watchLoading: (isLoading) => {
          this.loadingRecentBoards = isLoading;
        },
        error(error) {
          setError({
            error,
            message: s__(
              'Boards|An error occurred while fetching recent boards. Please try again.',
            ),
          });
        },
      });
    },
    addBoard(board) {
      const { defaultClient: store } = this.$apollo.provider.clients;

      const sourceData = store.readQuery({
        query: this.boardsQuery,
        variables: { fullPath: this.fullPath },
      });

      const newData = produce(sourceData, (draftState) => {
        draftState[this.parentType].boards.nodes = [
          ...draftState[this.parentType].boards.nodes,
          { ...board },
        ];
      });

      store.writeQuery({
        query: this.boardsQuery,
        variables: { fullPath: this.fullPath },
        data: newData,
      });

      this.$emit('switchBoard', board.id);
    },
    setFilterTerm(value) {
      this.filterTerm = value;
    },
    async switchBoardKeyEvent(boardId, e) {
      if (isModifierKey(e)) {
        e.stopPropagation();
        visitUrl(`${this.boardBaseUrl}/${boardId}`, true);
      }
    },
    switchBoardGroup(value) {
      // Epic board ID is supported in EE version of this file
      this.$emit('switchBoard', this.fullBoardId(value));
    },
  },
  formType,
};
</script>

<template>
  <div class="boards-switcher" data-testid="boards-selector">
    <span class="boards-selector-wrapper">
      <gl-collapsible-listbox
        v-if="showDropdown"
        block
        data-testid="boards-dropdown"
        searchable
        :searching="loading"
        toggle-class="gl-min-w-20"
        :header-text="$options.i18n.headerText"
        :no-results-text="$options.i18n.noResultsText"
        :loading="isCurrentBoardLoading"
        :items="listBoxItems"
        :toggle-text="boardName"
        :selected="boardId"
        @search="handleSearch"
        @select="switchBoardGroup"
        @shown="loadBoards"
      >
        <template #list-item="{ item }">
          <div data-testid="dropdown-item-recent" @click="switchBoardKeyEvent(item.value, $event)">
            {{ item.text }}
          </div>
        </template>

        <template #footer>
          <div v-if="hasMissingBoards" class="gl-border-t gl-px-4 gl-pb-3 gl-pt-4 gl-text-sm">
            {{ s__('Boards|Some of your boards are hidden, add a license to see them again.') }}
          </div>
          <div v-if="canAdminBoard" class="gl-border-t gl-px-2 gl-py-2">
            <gl-button
              v-if="showCreate"
              v-gl-modal-directive="'board-config-modal'"
              block
              class="!gl-justify-start"
              category="tertiary"
              data-testid="create-new-board-button"
              data-track-action="click_button"
              data-track-label="create_new_board"
              data-track-property="dropdown"
              @click="$emit('showBoardModal', $options.formType.new)"
            >
              {{ s__('Boards|Create new board') }}
            </gl-button>
          </div>
        </template>
      </gl-collapsible-listbox>

      <board-form
        v-if="boardModalForm"
        :can-admin-board="canAdminBoard"
        :scoped-issue-board-feature-enabled="scopedIssueBoardFeatureEnabled"
        :weights="weights"
        :current-board="board"
        :current-page="boardModalForm"
        :is-last-board="isLastBoard"
        :parent-type="parentType"
        @addBoard="addBoard"
        @updateBoard="$emit('updateBoard', $event)"
        @showBoardModal="$emit('showBoardModal', $event)"
        @shown="loadBoards"
        @cancel="cancel"
      />
    </span>
  </div>
</template>
