<script>
import { GlDrawer, GlLabel, GlAvatarLink, GlAvatarLabeled, GlLink } from '@gitlab/ui';
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
  labelMilestoneText: __('Milestone'),
  labelAssigneeText: __('Assignee'),
  components: {
    GlDrawer,
    GlLabel,
    GlAvatarLink,
    GlAvatarLabeled,
    GlLink,
    BoardSettingsSidebarWipLimit: () =>
      import('ee_component/boards/components/board_settings_wip_limit.vue'),
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
    activeListMilestone() {
      return this.activeList.milestone;
    },
    activeListAssignee() {
      return this.activeList.assignee;
    },
    boardListType() {
      return this.activeList.type || null;
    },
    listTypeTitle() {
      switch (this.boardListType) {
        case this.$options.milestone: {
          return this.$options.labelMilestoneText;
        }
        case this.$options.label: {
          return this.$options.labelListText;
        }
        case this.$options.assignee: {
          return this.$options.labelAssigneeText;
        }
        default: {
          return '';
        }
      }
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
      <div class="d-flex flex-column align-items-start">
        <label class="js-list-label">{{ listTypeTitle }}</label>
        <template v-if="boardListType === $options.label">
          <gl-label
            :title="activeListLabel.title"
            :background-color="activeListLabel.color"
            :scoped="showScopedLabels(activeListLabel)"
          />
        </template>
        <template v-else-if="boardListType === $options.assignee">
          <gl-avatar-link class="js-assignee" :href="activeListAssignee.webUrl">
            <gl-avatar-labeled
              :size="32"
              :label="activeListAssignee.name"
              :sub-label="`@${activeListAssignee.username}`"
              :src="activeListAssignee.avatar"
            />
          </gl-avatar-link>
        </template>
        <template v-else-if="boardListType === $options.milestone">
          <gl-link class="js-milestone" :href="activeListMilestone.webUrl">
            {{ activeListMilestone.title }}
          </gl-link>
        </template>
      </div>

      <board-settings-sidebar-wip-limit :max-issue-count="activeList.maxIssueCount" />
    </template>
  </gl-drawer>
</template>
