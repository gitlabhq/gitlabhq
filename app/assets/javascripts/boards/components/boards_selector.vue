<script>
import {
  GlLoadingIcon,
  GlSearchBoxByType,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlModalDirective,
} from '@gitlab/ui';
import { produce } from 'immer';
import { throttle } from 'lodash';
import { mapActions, mapState } from 'vuex';

import BoardForm from 'ee_else_ce/boards/components/board_form.vue';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isMetaKey } from '~/lib/utils/common_utils';
import { updateHistory } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

import eventHub from '../eventhub';
import groupBoardsQuery from '../graphql/group_boards.query.graphql';
import projectBoardsQuery from '../graphql/project_boards.query.graphql';
import groupRecentBoardsQuery from '../graphql/group_recent_boards.query.graphql';
import projectRecentBoardsQuery from '../graphql/project_recent_boards.query.graphql';
import { fullBoardId } from '../boards_util';

const MIN_BOARDS_TO_VIEW_RECENT = 10;

export default {
  name: 'BoardsSelector',
  components: {
    BoardForm,
    GlLoadingIcon,
    GlSearchBoxByType,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlDropdownItem,
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
    'isApolloBoard',
  ],
  props: {
    throttleDuration: {
      type: Number,
      default: 200,
      required: false,
    },
    boardApollo: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      hasScrollFade: false,
      scrollFadeInitialized: false,
      boards: [],
      recentBoards: [],
      loadingBoards: false,
      loadingRecentBoards: false,
      throttledSetScrollFade: throttle(this.setScrollFade, this.throttleDuration),
      contentClientHeight: 0,
      maxPosition: 0,
      filterTerm: '',
      currentPage: '',
    };
  },

  computed: {
    ...mapState(['board', 'isBoardLoading']),
    boardToUse() {
      return this.isApolloBoard ? this.boardApollo : this.board;
    },
    parentType() {
      return this.boardType;
    },
    boardQuery() {
      return this.isGroupBoard ? groupBoardsQuery : projectBoardsQuery;
    },
    loading() {
      return this.loadingRecentBoards || this.loadingBoards;
    },
    filteredBoards() {
      return this.boards.filter((board) =>
        board.name.toLowerCase().includes(this.filterTerm.toLowerCase()),
      );
    },
    showCreate() {
      return this.multipleIssueBoardsAvailable;
    },
    showDelete() {
      return this.boards.length > 1;
    },
    showDropdown() {
      return this.showCreate || this.hasMissingBoards;
    },
    scrollFadeClass() {
      return {
        'fade-out': !this.hasScrollFade,
      };
    },
    showRecentSection() {
      return (
        this.recentBoards.length &&
        this.boards.length > MIN_BOARDS_TO_VIEW_RECENT &&
        !this.filterTerm.length
      );
    },
  },
  watch: {
    filteredBoards() {
      this.scrollFadeInitialized = false;
      this.$nextTick(this.setScrollFade);
    },
    recentBoards() {
      this.scrollFadeInitialized = false;
      this.$nextTick(this.setScrollFade);
    },
    boardToUse(newBoard) {
      document.title = newBoard.name;
    },
  },
  created() {
    eventHub.$on('showBoardModal', this.showPage);
  },
  beforeDestroy() {
    eventHub.$off('showBoardModal', this.showPage);
  },
  methods: {
    ...mapActions(['setError', 'fetchBoard', 'unsetActiveId']),
    fullBoardId(boardId) {
      return fullBoardId(boardId);
    },
    showPage(page) {
      this.currentPage = page;
    },
    cancel() {
      this.showPage('');
    },
    boardUpdate(data, boardType) {
      if (!data?.[this.parentType]) {
        return [];
      }
      return data[this.parentType][boardType].edges.map(({ node }) => ({
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
        query: this.boardQuery,
        update: (data) => this.boardUpdate(data, 'boards'),
        watchLoading: (isLoading) => {
          this.loadingBoards = isLoading;
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
      });
    },
    addBoard(board) {
      const { defaultClient: store } = this.$apollo.provider.clients;

      const sourceData = store.readQuery({
        query: this.boardQuery,
        variables: { fullPath: this.fullPath },
      });

      const newData = produce(sourceData, (draftState) => {
        draftState[this.parentType].boards.edges = [
          ...draftState[this.parentType].boards.edges,
          { node: board },
        ];
      });

      store.writeQuery({
        query: this.boardQuery,
        variables: { fullPath: this.fullPath },
        data: newData,
      });

      this.$emit('switchBoard', board.id);
    },
    isScrolledUp() {
      const { content } = this.$refs;

      if (!content) {
        return false;
      }

      const currentPosition = this.contentClientHeight + content.scrollTop;

      return currentPosition < this.maxPosition;
    },
    initScrollFade() {
      const { content } = this.$refs;

      if (!content) {
        return;
      }

      this.scrollFadeInitialized = true;

      this.contentClientHeight = content.clientHeight;
      this.maxPosition = content.scrollHeight;
    },
    setScrollFade() {
      if (!this.scrollFadeInitialized) this.initScrollFade();

      this.hasScrollFade = this.isScrolledUp();
    },
    fetchCurrentBoard(boardId) {
      this.fetchBoard({
        fullPath: this.fullPath,
        fullBoardId: fullBoardId(boardId),
        boardType: this.boardType,
      });
    },
    async switchBoard(boardId, e) {
      if (isMetaKey(e)) {
        window.open(`${this.boardBaseUrl}/${boardId}`, '_blank');
      } else if (this.isApolloBoard) {
        // Epic board ID is supported in EE version of this file
        this.$emit('switchBoard', this.fullBoardId(boardId));
        updateHistory({ url: `${this.boardBaseUrl}/${boardId}` });
      } else {
        this.unsetActiveId();
        this.fetchCurrentBoard(boardId);
        updateHistory({ url: `${this.boardBaseUrl}/${boardId}` });
      }
    },
  },
  i18n: {
    errorFetchingBoard: s__('Board|An error occurred while fetching the board, please try again.'),
  },
};
</script>

<template>
  <div class="boards-switcher gl-mr-3" data-testid="boards-selector">
    <span class="boards-selector-wrapper">
      <gl-dropdown
        v-if="showDropdown"
        data-testid="boards-dropdown"
        data-qa-selector="boards_dropdown"
        toggle-class="dropdown-menu-toggle"
        menu-class="flex-column dropdown-extended-height"
        :loading="isBoardLoading"
        :text="boardToUse.name"
        @show="loadBoards"
      >
        <p class="gl-dropdown-header-top" @mousedown.prevent>
          {{ s__('IssueBoards|Switch board') }}
        </p>
        <gl-search-box-by-type ref="searchBox" v-model="filterTerm" class="m-2" />

        <div
          v-if="!loading"
          ref="content"
          data-qa-selector="boards_dropdown_content"
          class="dropdown-content flex-fill"
          @scroll.passive="throttledSetScrollFade"
        >
          <gl-dropdown-item
            v-show="filteredBoards.length === 0"
            class="gl-pointer-events-none text-secondary"
          >
            {{ s__('IssueBoards|No matching boards found') }}
          </gl-dropdown-item>

          <gl-dropdown-section-header v-if="showRecentSection">
            {{ __('Recent') }}
          </gl-dropdown-section-header>

          <template v-if="showRecentSection">
            <gl-dropdown-item
              v-for="recentBoard in recentBoards"
              :key="`recent-${recentBoard.id}`"
              data-testid="dropdown-item"
              @click.prevent="switchBoard(recentBoard.id, $event)"
            >
              {{ recentBoard.name }}
            </gl-dropdown-item>
          </template>

          <gl-dropdown-divider v-if="showRecentSection" />

          <gl-dropdown-section-header v-if="showRecentSection">
            {{ __('All') }}
          </gl-dropdown-section-header>

          <gl-dropdown-item
            v-for="otherBoard in filteredBoards"
            :key="otherBoard.id"
            data-testid="dropdown-item"
            @click.prevent="switchBoard(otherBoard.id, $event)"
          >
            {{ otherBoard.name }}
          </gl-dropdown-item>

          <gl-dropdown-item v-if="hasMissingBoards" class="no-pointer-events">
            {{
              s__('IssueBoards|Some of your boards are hidden, add a license to see them again.')
            }}
          </gl-dropdown-item>
        </div>

        <div
          v-show="filteredBoards.length > 0"
          class="dropdown-content-faded-mask"
          :class="scrollFadeClass"
        ></div>

        <gl-loading-icon v-if="loading" size="sm" />

        <div v-if="canAdminBoard">
          <gl-dropdown-divider />

          <gl-dropdown-item
            v-if="showCreate"
            v-gl-modal-directive="'board-config-modal'"
            data-qa-selector="create_new_board_button"
            data-track-action="click_button"
            data-track-label="create_new_board"
            data-track-property="dropdown"
            @click.prevent="showPage('new')"
          >
            {{ s__('IssueBoards|Create new board') }}
          </gl-dropdown-item>

          <gl-dropdown-item
            v-if="showDelete"
            v-gl-modal-directive="'board-config-modal'"
            class="text-danger"
            @click.prevent="showPage('delete')"
          >
            {{ s__('IssueBoards|Delete board') }}
          </gl-dropdown-item>
        </div>
      </gl-dropdown>

      <board-form
        v-if="currentPage"
        :can-admin-board="canAdminBoard"
        :scoped-issue-board-feature-enabled="scopedIssueBoardFeatureEnabled"
        :weights="weights"
        :current-board="boardToUse"
        :current-page="currentPage"
        @addBoard="addBoard"
        @cancel="cancel"
      />
    </span>
  </div>
</template>
