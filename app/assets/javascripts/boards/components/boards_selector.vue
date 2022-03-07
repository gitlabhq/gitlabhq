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
import { mapActions, mapGetters, mapState } from 'vuex';

import BoardForm from 'ee_else_ce/boards/components/board_form.vue';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';

import eventHub from '../eventhub';
import groupBoardsQuery from '../graphql/group_boards.query.graphql';
import projectBoardsQuery from '../graphql/project_boards.query.graphql';
import groupBoardQuery from '../graphql/group_board.query.graphql';
import projectBoardQuery from '../graphql/project_board.query.graphql';
import groupRecentBoardsQuery from '../graphql/group_recent_boards.query.graphql';
import projectRecentBoardsQuery from '../graphql/project_recent_boards.query.graphql';

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
  inject: ['fullPath'],
  props: {
    throttleDuration: {
      type: Number,
      default: 200,
      required: false,
    },
    boardBaseUrl: {
      type: String,
      required: true,
    },
    hasMissingBoards: {
      type: Boolean,
      required: true,
    },
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    multipleIssueBoardsAvailable: {
      type: Boolean,
      required: true,
    },
    scopedIssueBoardFeatureEnabled: {
      type: Boolean,
      required: true,
    },
    weights: {
      type: Array,
      required: true,
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
      board: {},
    };
  },
  apollo: {
    board: {
      query() {
        return this.currentBoardQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          boardId: this.fullBoardId,
        };
      },
      update(data) {
        const board = data.workspace?.board;
        return {
          ...board,
          labels: board?.labels?.nodes,
        };
      },
      error() {
        this.setError({ message: this.$options.i18n.errorFetchingBoard });
      },
    },
  },
  computed: {
    ...mapState(['boardType', 'fullBoardId']),
    ...mapGetters(['isGroupBoard', 'isProjectBoard']),
    parentType() {
      return this.boardType;
    },
    currentBoardQueryCE() {
      return this.isGroupBoard ? groupBoardQuery : projectBoardQuery;
    },
    currentBoardQuery() {
      return this.currentBoardQueryCE;
    },
    isBoardLoading() {
      return this.$apollo.queries.board.loading;
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
  },
  created() {
    eventHub.$on('showBoardModal', this.showPage);
  },
  beforeDestroy() {
    eventHub.$off('showBoardModal', this.showPage);
  },
  methods: {
    ...mapActions(['setError']),
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
  },
  i18n: {
    errorFetchingBoard: s__('Board|An error occurred while fetching the board, please try again.'),
  },
};
</script>

<template>
  <div class="boards-switcher js-boards-selector gl-mr-3">
    <span class="boards-selector-wrapper js-boards-selector-wrapper">
      <gl-dropdown
        data-qa-selector="boards_dropdown"
        toggle-class="dropdown-menu-toggle js-dropdown-toggle"
        menu-class="flex-column dropdown-extended-height"
        :loading="isBoardLoading"
        :text="board.name"
        @show="loadBoards"
      >
        <p class="gl-new-dropdown-header-top" @mousedown.prevent>
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
              class="js-dropdown-item"
              :href="`${boardBaseUrl}/${recentBoard.id}`"
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
            class="js-dropdown-item"
            :href="`${boardBaseUrl}/${otherBoard.id}`"
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
            class="text-danger js-delete-board"
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
        :current-board="board"
        :current-page="currentPage"
        @cancel="cancel"
      />
    </span>
  </div>
</template>
