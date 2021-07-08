<script>
import { GlButton, GlDrawer, GlLabel } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { mapActions, mapState, mapGetters } from 'vuex';
import { LIST, ListType, ListTypeTitles } from '~/boards/constants';
import boardsStore from '~/boards/stores/boards_store';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  listSettingsText: __('List settings'),
  components: {
    GlButton,
    GlDrawer,
    GlLabel,
    MountingPortal,
    BoardSettingsSidebarWipLimit: () =>
      import('ee_component/boards/components/board_settings_wip_limit.vue'),
    BoardSettingsListTypes: () =>
      import('ee_component/boards/components/board_settings_list_types.vue'),
  },
  mixins: [glFeatureFlagMixin(), Tracking.mixin()],
  inject: ['canAdminList'],
  inheritAttrs: false,
  data() {
    return {
      ListType,
    };
  },
  computed: {
    ...mapGetters(['isSidebarOpen', 'shouldUseGraphQL', 'isEpicBoard']),
    ...mapState(['activeId', 'sidebarType', 'boardLists']),
    isWipLimitsOn() {
      return this.glFeatures.wipLimits && !this.isEpicBoard;
    },
    activeList() {
      /*
        Warning: Though a computed property it is not reactive because we are
        referencing a List Model class. Reactivity only applies to plain JS objects
      */
      if (this.shouldUseGraphQL || this.isEpicBoard) {
        return this.boardLists[this.activeId];
      }
      return boardsStore.state.lists.find(({ id }) => id === this.activeId);
    },
    activeListLabel() {
      return this.activeList.label;
    },
    boardListType() {
      return this.activeList.type || this.activeList.listType || null;
    },
    listTypeTitle() {
      return ListTypeTitles[ListType.label];
    },
    showSidebar() {
      return this.sidebarType === LIST;
    },
  },
  created() {
    eventHub.$on('sidebar.closeAll', this.unsetActiveId);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.closeAll', this.unsetActiveId);
  },
  methods: {
    ...mapActions(['unsetActiveId', 'removeList']),
    showScopedLabels(label) {
      return boardsStore.scopedLabels.enabled && isScopedLabel(label);
    },
    deleteBoard() {
      // eslint-disable-next-line no-alert
      if (window.confirm(__('Are you sure you want to remove this list?'))) {
        if (this.shouldUseGraphQL || this.isEpicBoard) {
          this.track('click_button', { label: 'remove_list' });
          this.removeList(this.activeId);
        } else {
          this.activeList.destroy();
        }
        this.unsetActiveId();
      }
    },
  },
};
</script>

<template>
  <mounting-portal mount-to="#js-right-sidebar-portal" name="board-settings-sidebar" append>
    <gl-drawer
      v-if="showSidebar"
      v-bind="$attrs"
      class="js-board-settings-sidebar gl-absolute"
      :open="isSidebarOpen"
      @close="unsetActiveId"
    >
      <template #title>{{ $options.listSettingsText }}</template>
      <template v-if="isSidebarOpen">
        <div v-if="boardListType === ListType.label">
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
        <board-settings-sidebar-wip-limit
          v-if="isWipLimitsOn"
          :max-issue-count="activeList.maxIssueCount"
        />
        <div v-if="canAdminList && !activeList.preset && activeList.id" class="gl-mt-4">
          <gl-button
            variant="danger"
            category="secondary"
            icon="remove"
            data-testid="remove-list"
            @click.stop="deleteBoard"
            >{{ __('Remove list') }}
          </gl-button>
        </div>
      </template>
    </gl-drawer>
  </mounting-portal>
</template>
