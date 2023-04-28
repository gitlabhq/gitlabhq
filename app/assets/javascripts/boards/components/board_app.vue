<script>
import { mapGetters } from 'vuex';
import { refreshCurrentPage, queryToObject } from '~/lib/utils/url_utility';
import BoardContent from '~/boards/components/board_content.vue';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import BoardTopBar from '~/boards/components/board_top_bar.vue';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';

export default {
  components: {
    BoardContent,
    BoardSettingsSidebar,
    BoardTopBar,
  },
  inject: ['initialBoardId', 'initialFilterParams', 'isIssueBoard', 'isApolloBoard'],
  data() {
    return {
      activeListId: '',
      boardId: this.initialBoardId,
      filterParams: { ...this.initialFilterParams },
      isShowingEpicsSwimlanes: Boolean(queryToObject(window.location.search).group_by),
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
  },

  computed: {
    ...mapGetters(['isSidebarOpen']),
    isSwimlanesOn() {
      return (gon?.licensed_features?.swimlanes && this.isShowingEpicsSwimlanes) ?? false;
    },
    isAnySidebarOpen() {
      if (this.isApolloBoard) {
        return this.activeBoardItem?.id || this.activeListId;
      }
      return this.isSidebarOpen;
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
      :board-id="boardId"
      :is-swimlanes-on="isSwimlanesOn"
      :filter-params="filterParams"
      @setActiveList="setActiveId"
    />
    <board-settings-sidebar
      :list-id="activeListId"
      :board-id="boardId"
      @unsetActiveId="setActiveId('')"
    />
  </div>
</template>
