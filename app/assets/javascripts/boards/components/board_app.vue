<script>
import { mapActions, mapGetters } from 'vuex';
import BoardContent from '~/boards/components/board_content.vue';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import BoardTopBar from '~/boards/components/board_top_bar.vue';

export default {
  components: {
    BoardContent,
    BoardSettingsSidebar,
    BoardTopBar,
  },
  inject: ['disabled'],
  computed: {
    ...mapGetters(['isSidebarOpen']),
  },
  mounted() {
    this.performSearch();
  },
  methods: {
    ...mapActions(['performSearch']),
  },
};
</script>

<template>
  <div class="boards-app gl-relative" :class="{ 'is-compact': isSidebarOpen }">
    <board-top-bar />
    <board-content :disabled="disabled" />
    <board-settings-sidebar />
  </div>
</template>
