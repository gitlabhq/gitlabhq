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
  inject: ['fullBoardId'],
  computed: {
    ...mapGetters(['isSidebarOpen']),
  },
  created() {
    window.addEventListener('popstate', refreshCurrentPage);
  },
  destroyed() {
    window.removeEventListener('popstate', refreshCurrentPage);
  },
};
</script>

<template>
  <div class="boards-app gl-relative" :class="{ 'is-compact': isSidebarOpen }">
    <board-top-bar />
    <board-content :board-id="fullBoardId" />
    <board-settings-sidebar />
  </div>
</template>
