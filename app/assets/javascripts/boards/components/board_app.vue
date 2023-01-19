<script>
import { mapGetters } from 'vuex';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import BoardContent from '~/boards/components/board_content.vue';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import BoardTopBar from '~/boards/components/board_top_bar.vue';

export default {
  components: {
    BoardContent,
    BoardSettingsSidebar,
    BoardTopBar,
  },
  inject: ['initialBoardId'],
  data() {
    return {
      boardId: this.initialBoardId,
    };
  },
  computed: {
    ...mapGetters(['isSidebarOpen']),
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
  },
};
</script>

<template>
  <div class="boards-app gl-relative" :class="{ 'is-compact': isSidebarOpen }">
    <board-top-bar :board-id="boardId" @switchBoard="switchBoard" />
    <board-content :board-id="boardId" />
    <board-settings-sidebar />
  </div>
</template>
