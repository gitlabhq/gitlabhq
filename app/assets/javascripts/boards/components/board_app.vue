<script>
import { omit } from 'lodash';
import { refreshCurrentPage, queryToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import BoardContent from '~/boards/components/board_content.vue';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import BoardTopBar from '~/boards/components/board_top_bar.vue';
import { listsQuery, FilterFields } from 'ee_else_ce/boards/constants';
import { formatBoardLists, filterVariables, FiltersInfo } from 'ee_else_ce/boards/boards_util';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import errorQuery from '../graphql/client/error.query.graphql';
import { setError } from '../graphql/cache_updates';

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
  ],
  data() {
    return {
      boardLists: {},
      activeListId: '',
      boardId: this.initialBoardId,
      filterParams: { ...this.initialFilterParams },
      addColumnFormVisible: false,
      isShowingEpicsSwimlanes: Boolean(queryToObject(window.location.search).group_by),
      error: null,
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
        if (activeBoardItem && activeBoardItem.listId !== null) {
          this.setActiveId('');
        }
      },
    },
    boardLists: {
      query() {
        return listsQuery[this.issuableType].query;
      },
      variables() {
        return this.listQueryVariables;
      },
      update(data) {
        const { lists } = data[this.boardType].board;
        return formatBoardLists(lists);
      },
      error(error) {
        setError({
          error,
          message: this.$options.i18n.fetchError,
        });
      },
    },
    error: {
      query: errorQuery,
      update: (data) => data.boardsAppError,
    },
  },

  computed: {
    listQueryVariables() {
      return {
        ...(this.isIssueBoard && {
          isGroup: this.isGroupBoard,
          isProject: !this.isGroupBoard,
        }),
        fullPath: this.fullPath,
        boardId: this.boardId,
        filters: this.formattedFilterParams,
      };
    },
    isSwimlanesOn() {
      return (gon?.licensed_features?.swimlanes && this.isShowingEpicsSwimlanes) ?? false;
    },
    isAnySidebarOpen() {
      return this.activeBoardItem?.id || this.activeListId;
    },
    activeList() {
      return this.activeListId ? this.boardLists[this.activeListId] : undefined;
    },
    formattedFilterParams() {
      return filterVariables({
        filters: omit(this.filterParams, 'groupBy'),
        issuableType: this.issuableType,
        filterInfo: FiltersInfo,
        filterFields: FilterFields,
      });
    },
  },
  created() {
    window.addEventListener('popstate', refreshCurrentPage);
  },
  destroyed() {
    window.removeEventListener('popstate', refreshCurrentPage);
  },
  methods: {
    refetchLists() {
      this.$apollo.queries.boardLists.refetch();
    },
    setActiveId(id) {
      this.activeListId = id;
    },
    switchBoard(id) {
      this.boardId = id;
      this.setActiveId('');
    },
    setFilters(filters) {
      const filterParams = { ...filters };
      this.filterParams = filterParams;
    },
  },
};
</script>

<template>
  <div class="boards-app gl-relative" :class="{ 'is-compact': isAnySidebarOpen }">
    <board-top-bar
      :board-id="boardId"
      :add-column-form-visible="addColumnFormVisible"
      :is-swimlanes-on="isSwimlanesOn"
      :filters="filterParams"
      @switchBoard="switchBoard"
      @setFilters="setFilters"
      @setAddColumnFormVisibility="addColumnFormVisible = $event"
      @toggleSwimlanes="isShowingEpicsSwimlanes = $event"
      @updateBoard="refetchLists"
    />
    <board-content
      :board-id="boardId"
      :add-column-form-visible="addColumnFormVisible"
      :is-swimlanes-on="isSwimlanesOn"
      :filter-params="formattedFilterParams"
      :board-lists="boardLists"
      :error="error"
      :list-query-variables="listQueryVariables"
      @setActiveList="setActiveId"
      @setAddColumnFormVisibility="addColumnFormVisible = $event"
      @setFilters="setFilters"
    />
    <board-settings-sidebar
      v-if="activeList"
      :list="activeList"
      :list-id="activeListId"
      :board-id="boardId"
      :query-variables="listQueryVariables"
      @unsetActiveId="setActiveId('')"
    />
  </div>
</template>
