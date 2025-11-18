<script>
import { omit } from 'lodash';
import AccessorUtilities from '~/lib/utils/accessor';
import { historyPushState, parseBoolean } from '~/lib/utils/common_utils';
import { queryToObject, mergeUrlParams, removeParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import BoardContent from '~/boards/components/board_content.vue';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import BoardTopBar from '~/boards/components/board_top_bar.vue';
import { listsQuery, FilterFields, GroupByParamType } from 'ee_else_ce/boards/constants';
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
    'hasCustomFieldsFeature',
  ],
  data() {
    return {
      boardLists: {},
      activeListId: '',
      boardId: this.initialBoardId,
      filterParams: { ...this.initialFilterParams },
      addColumnFormVisible: false,
      isShowingEpicsSwimlanes: false,
      error: null,
      isWorkItemDrawerOpened: false,
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
        options: { hasCustomFieldsFeature: this.hasCustomFieldsFeature },
      });
    },
    isShowingEpicSwimlanesLocalStorageKey() {
      return `board.${this.fullPath}.${this.boardId}.isShowingEpicSwimlanes`;
    },
    isBoardWidthDynamic() {
      return this.isAnySidebarOpen && this.isWorkItemDrawerOpened;
    },
  },
  created() {
    this.initIsShowingEpicSwimlanes();
  },
  methods: {
    refetchLists() {
      this.$apollo.queries.boardLists.refetch();
    },
    setActiveId(id) {
      this.activeListId = id;
      if (!id && !this.isAnySidebarOpen) this.isWorkItemDrawerOpened = false;
    },
    switchBoard(id) {
      this.boardId = id;
      this.setActiveId('');
      this.setIsShowingEpicSwimlanesFromLocalStorage();
    },
    setFilters(filters) {
      const filterParams = { ...filters };
      this.filterParams = filterParams;
    },
    setIsShowingEpicSwimlanes(value) {
      this.isShowingEpicsSwimlanes = value;
      this.saveIsShowingEpicSwimlanes();
    },
    getIsShowingEpicSwimlanesFromUrl() {
      return queryToObject(window.location.search).group_by === GroupByParamType.epic;
    },
    getIsShowingEpicSwimlanesFromLocalStorage() {
      return parseBoolean(localStorage.getItem(this.isShowingEpicSwimlanesLocalStorageKey));
    },
    setIsShowingEpicSwimlanesFromLocalStorage() {
      if (AccessorUtilities.canUseLocalStorage()) {
        this.isShowingEpicsSwimlanes = this.getIsShowingEpicSwimlanesFromLocalStorage();
        if (this.isShowingEpicsSwimlanes) {
          historyPushState(
            mergeUrlParams({ group_by: GroupByParamType.epic }, window.location.href, {
              spreadArrays: true,
            }),
          );
        } else {
          this.removeGroupByParam();
        }
      }
    },
    initIsShowingEpicSwimlanes() {
      if (this.isIssueBoard) {
        const urlHasEpicSwimlanes = this.getIsShowingEpicSwimlanesFromUrl();
        this.setIsShowingEpicSwimlanes(urlHasEpicSwimlanes);
        if (urlHasEpicSwimlanes) {
          return;
        }
        if (this.getIsShowingEpicSwimlanesFromLocalStorage()) {
          this.setIsShowingEpicSwimlanes(true);
        }
      } else {
        this.removeGroupByParam();
      }
    },
    saveIsShowingEpicSwimlanes() {
      if (AccessorUtilities.canUseLocalStorage()) {
        const currentLocalStorageValue = this.getIsShowingEpicSwimlanesFromLocalStorage();
        if (currentLocalStorageValue !== this.isShowingEpicsSwimlanes) {
          localStorage.setItem(
            this.isShowingEpicSwimlanesLocalStorageKey,
            this.isShowingEpicsSwimlanes,
          );
        }
      }
    },
    removeGroupByParam() {
      historyPushState(removeParams(['group_by']), window.location.href, true);
    },
    handleWorkItemDrawerClose() {
      if (!this.isAnySidebarOpen) {
        this.isWorkItemDrawerOpened = false;
      }
    },
  },
};
</script>

<template>
  <div class="boards-app gl-relative">
    <router-view />
    <board-top-bar
      :board-id="boardId"
      :is-swimlanes-on="isSwimlanesOn"
      :filters="filterParams"
      @switchBoard="switchBoard"
      @setFilters="setFilters"
      @setAddColumnFormVisibility="addColumnFormVisible = $event"
      @toggleSwimlanes="setIsShowingEpicSwimlanes"
      @updateBoard="refetchLists"
    />
    <board-content
      class="board-content"
      :class="{
        '@lg/panel:gl-w-[calc(100%-480px)] @xl/panel:gl-w-[calc(100%-768px)] min-[1440px]:gl-w-[calc(100%-912px)]':
          isBoardWidthDynamic,
      }"
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
      @drawer-closed="handleWorkItemDrawerClose"
      @drawer-opened="isWorkItemDrawerOpened = true"
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
