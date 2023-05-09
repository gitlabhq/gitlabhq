<script>
import { mapGetters } from 'vuex';
import { refreshCurrentPage, queryToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import BoardContent from '~/boards/components/board_content.vue';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import BoardTopBar from '~/boards/components/board_top_bar.vue';
import { listsQuery } from 'ee_else_ce/boards/constants';
import { formatBoardLists } from 'ee_else_ce/boards/boards_util';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';

export default {
  i18n: {
    fetchError: s__(
      'Boards|An error occurred while fetching the board lists. Please reload the page.',
    ),
  },
  components: {
    BoardContent,
    BoardSettingsSidebar,
    BoardTopBar,
  },
  inject: [
    'fullPath',
    'initialBoardId',
    'initialFilterParams',
    'isIssueBoard',
    'isGroupBoard',
    'issuableType',
    'boardType',
    'isApolloBoard',
  ],
  data() {
    return {
      activeListId: '',
      boardId: this.initialBoardId,
      filterParams: { ...this.initialFilterParams },
      isShowingEpicsSwimlanes: Boolean(queryToObject(window.location.search).group_by),
      apolloError: null,
    };
  },
  apollo: {
    activeBoardItem: {
      query: activeBoardItemQuery,
      variables() {
        return {
          isIssue: this.isIssueBoard,
        };
      },
      result({ data: { activeBoardItem } }) {
        if (activeBoardItem) {
          this.setActiveId('');
        }
      },
      skip() {
        return !this.isApolloBoard;
      },
    },
    boardListsApollo: {
      query() {
        return listsQuery[this.issuableType].query;
      },
      variables() {
        return this.listQueryVariables;
      },
      skip() {
        return !this.isApolloBoard;
      },
      update(data) {
        const { lists } = data[this.boardType].board;
        return formatBoardLists(lists);
      },
      error() {
        this.apolloError = this.$options.i18n.fetchError;
      },
    },
  },

  computed: {
    ...mapGetters(['isSidebarOpen']),
    listQueryVariables() {
      return {
        ...(this.isIssueBoard && {
          isGroup: this.isGroupBoard,
          isProject: !this.isGroupBoard,
        }),
        fullPath: this.fullPath,
        boardId: this.boardId,
        filters: this.filterParams,
      };
    },
    isSwimlanesOn() {
      return (gon?.licensed_features?.swimlanes && this.isShowingEpicsSwimlanes) ?? false;
    },
    isAnySidebarOpen() {
      if (this.isApolloBoard) {
        return this.activeBoardItem?.id || this.activeListId;
      }
      return this.isSidebarOpen;
    },
    activeList() {
      return this.activeListId ? this.boardListsApollo[this.activeListId] : undefined;
    },
  },
  created() {
    window.addEventListener('popstate', refreshCurrentPage);
  },
  destroyed() {
    window.removeEventListener('popstate', refreshCurrentPage);
  },
  methods: {
    setActiveId(id) {
      this.activeListId = id;
    },
    switchBoard(id) {
      this.boardId = id;
      this.setActiveId('');
    },
    setFilters(filters) {
      const filterParams = { ...filters };
      if (filterParams.groupBy) delete filterParams.groupBy;
      this.filterParams = filterParams;
    },
  },
};
</script>

<template>
  <div class="boards-app gl-relative" :class="{ 'is-compact': isAnySidebarOpen }">
    <board-top-bar
      :board-id="boardId"
      :is-swimlanes-on="isSwimlanesOn"
      @switchBoard="switchBoard"
      @setFilters="setFilters"
      @toggleSwimlanes="isShowingEpicsSwimlanes = $event"
    />
    <board-content
      v-if="!isApolloBoard || boardListsApollo"
      :board-id="boardId"
      :is-swimlanes-on="isSwimlanesOn"
      :filter-params="filterParams"
      :board-lists-apollo="boardListsApollo"
      :apollo-error="apolloError"
      @setActiveList="setActiveId"
    />
    <board-settings-sidebar
      v-if="!isApolloBoard || activeList"
      :list="activeList"
      :list-id="activeListId"
      :board-id="boardId"
      :query-variables="listQueryVariables"
      @unsetActiveId="setActiveId('')"
    />
  </div>
</template>
