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
      loadingBoards: 0,
      loadingRecentBoards: false,
      scrollFadeInitialized: false,
      boards: [],
      recentBoards: [],
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
    loading() {
      return this.loadingRecentBoards || Boolean(this.loadingBoards);
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
    boardQuery() {
      return this.isGroupBoard ? groupBoardsQuery : projectBoardsQuery;
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
        loadingKey: 'loadingBoards',
        update: (data) => this.boardUpdate(data, 'boards'),
      });

      this.loadRecentBoards();
    },
    loadRecentBoards() {
      this.$apollo.addSmartQuery('recentBoards', {
        variables() {
          return { fullPath: this.fullPath };
        },
        query: this.recentBoardsQuery,
        loadingKey: 'loadingRecentBoards',
        update: (data) => this.boardUpdate(data, 'recentIssueBoards'),
      });
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
    fullBoardId(boardId) {
      return fullBoardId(boardId);
    },
    async switchBoard(boardId, e) {
      if (isMetaKey(e)) {
        window.open(`${this.boardBaseUrl}/${boardId}`, '_blank');
      } else if (this.isApolloBoard) {
        this.$emit('switchBoard', this.fullBoardId(boardId));
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
        @cancel="cancel"
      />
    </span>
  </div>
</template>
