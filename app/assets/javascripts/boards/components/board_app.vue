<script>
import { mapGetters } from 'vuex';
import { refreshCurrentPage, queryToObject } from '~/lib/utils/url_utility';
import BoardContent from '~/boards/components/board_content.vue';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import BoardTopBar from '~/boards/components/board_top_bar.vue';

export default {
  components: {
    BoardContent,
    BoardSettingsSidebar,
    BoardTopBar,
  },
  inject: ['initialBoardId', 'initialFilterParams'],
  data() {
    return {
      boardId: this.initialBoardId,
      filterParams: { ...this.initialFilterParams },
      isShowingEpicsSwimlanes: Boolean(queryToObject(window.location.search).group_by),
    };
  },
  computed: {
    ...mapGetters(['isSidebarOpen']),
    isSwimlanesOn() {
      return (gon?.licensed_features?.swimlanes && this.isShowingEpicsSwimlanes) ?? false;
    },
  },
  created() {
    window.addEventListener('popstate', refreshCurrentPage);
  },
  destroyed() {
    window.removeEventListener('popstate', refreshCurrentPage);
  },
  methods: {
    switchBoard(id) {
      this.boardId = id;
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
  <div class="boards-app gl-relative" :class="{ 'is-compact': isSidebarOpen }">
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
    />
    <board-settings-sidebar />
  </div>
</template>
