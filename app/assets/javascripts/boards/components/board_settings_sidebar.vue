<script>
import { GlButton, GlDrawer, GlLabel } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';
import boardsStore from '~/boards/stores/boards_store';
import eventHub from '~/sidebar/event_hub';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { LIST } from '~/boards/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

// NOTE: need to revisit how we handle headerHeight, because we have so many different header and footer options.
export default {
  headerHeight: process.env.NODE_ENV === 'development' ? '75px' : '40px',
  listSettingsText: __('List settings'),
  assignee: 'assignee',
  milestone: 'milestone',
  label: 'label',
  labelListText: __('Label'),
  components: {
    GlButton,
    GlDrawer,
    GlLabel,
    BoardSettingsSidebarWipLimit: () =>
      import('ee_component/boards/components/board_settings_wip_limit.vue'),
    BoardSettingsListTypes: () =>
      import('ee_component/boards/components/board_settings_list_types.vue'),
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['isSidebarOpen', 'shouldUseGraphQL']),
    ...mapState(['activeId', 'sidebarType', 'boardLists']),
    isWipLimitsOn() {
      return this.glFeatures.wipLimits;
    },
    activeList() {
      /*
        Warning: Though a computed property it is not reactive because we are
        referencing a List Model class. Reactivity only applies to plain JS objects
      */
      if (this.shouldUseGraphQL) {
        return this.boardLists[this.activeId];
      }
      return boardsStore.state.lists.find(({ id }) => id === this.activeId);
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
        if (this.shouldUseGraphQL) {
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
  <gl-drawer
    v-if="showSidebar"
    class="js-board-settings-sidebar"
    :open="isSidebarOpen"
    :header-height="$options.headerHeight"
    @close="unsetActiveId"
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
      <board-settings-sidebar-wip-limit
        v-if="isWipLimitsOn"
        :max-issue-count="activeList.maxIssueCount"
      />
      <div v-if="canAdminList && !activeList.preset && activeList.id" class="gl-m-4">
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
</template>
