<script>
import { GlDrawer, GlLabel } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import boardsStore from '~/boards/stores/boards_store';
import eventHub from '~/sidebar/event_hub';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { inactiveId } from '~/boards/constants';

// NOTE: need to revisit how we handle headerHeight, because we have so many different header and footer options.
export default {
  headerHeight: process.env.NODE_ENV === 'development' ? '75px' : '40px',
  listSettingsText: __('List settings'),
  assignee: 'assignee',
  milestone: 'milestone',
  label: 'label',
  labelListText: __('Label'),
  components: {
    GlDrawer,
    GlLabel,
    BoardSettingsSidebarWipLimit: () =>
      import('ee_component/boards/components/board_settings_wip_limit.vue'),
    BoardSettingsListTypes: () =>
      import('ee_component/boards/components/board_settings_list_types.vue'),
  },
  computed: {
    ...mapState(['activeId']),
    activeList() {
      /*
        Warning: Though a computed property it is not reactive because we are
        referencing a List Model class. Reactivity only applies to plain JS objects
      */
      return boardsStore.state.lists.find(({ id }) => id === this.activeId);
    },
    isSidebarOpen() {
      return this.activeId !== inactiveId;
    },
    activeListLabel() {
      return this.activeList.label;
    },
    boardListType() {
      return this.activeList.type || null;
    },
    listTypeTitle() {
      return this.$options.labelListText;
    },
  },
  created() {
    eventHub.$on('sidebar.closeAll', this.closeSidebar);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.closeAll', this.closeSidebar);
  },
  methods: {
    ...mapActions(['setActiveId']),
    closeSidebar() {
      this.setActiveId(inactiveId);
    },
    showScopedLabels(label) {
      return boardsStore.scopedLabels.enabled && isScopedLabel(label);
    },
  },
};
</script>

<template>
  <gl-drawer
    class="js-board-settings-sidebar"
    :open="isSidebarOpen"
    :header-height="$options.headerHeight"
    @close="closeSidebar"
  >
    <template #header>{{ $options.listSettingsText }}</template>
    <template v-if="isSidebarOpen">
      <div v-if="boardListType === $options.label">
        <label class="js-list-label gl-display-block">{{ listTypeTitle }}</label>
        <gl-label
          :title="activeListLabel.title"
          :background-color="activeListLabel.color"
          :scoped="showScopedLabels(activeListLabel)"
        />
      </div>

      <board-settings-list-types
        v-else
        :active-list="activeList"
        :board-list-type="boardListType"
      />
      <board-settings-sidebar-wip-limit :max-issue-count="activeList.maxIssueCount" />
    </template>
  </gl-drawer>
</template>
