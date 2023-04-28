<script>
import { GlButton, GlDrawer, GlLabel, GlLoadingIcon, GlModal, GlModalDirective } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { mapActions, mapState, mapGetters } from 'vuex';
import { LIST, ListType, ListTypeTitles, listsQuery } from 'ee_else_ce/boards/constants';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  listSettingsText: __('List settings'),
  i18n: {
    modalAction: __('Remove list'),
    modalCopy: __('Are you sure you want to remove this list?'),
    modalCancel: __('Cancel'),
  },
  components: {
    GlButton,
    GlModal,
    GlDrawer,
    GlLabel,
    GlLoadingIcon,
    MountingPortal,
    BoardSettingsSidebarWipLimit: () =>
      import('ee_component/boards/components/board_settings_wip_limit.vue'),
    BoardSettingsListTypes: () =>
      import('ee_component/boards/components/board_settings_list_types.vue'),
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagMixin(), Tracking.mixin()],
  inject: [
    'boardType',
    'canAdminList',
    'fullPath',
    'issuableType',
    'scopedLabelsAvailable',
    'isIssueBoard',
    'isGroupBoard',
    'isApolloBoard',
  ],
  inheritAttrs: false,
  props: {
    listId: {
      type: String,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      ListType,
      list: {},
    };
  },
  modalId: 'board-settings-sidebar-modal',
  apollo: {
    list: {
      query() {
        return listsQuery[this.issuableType].query;
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        const { lists } = data[this.boardType].board;
        return lists.nodes[0];
      },
      skip() {
        return !this.isApolloBoard || !this.listId;
      },
      error() {
        this.error = this.$options.i18n.fetchError;
      },
    },
  },
  computed: {
    ...mapGetters(['isSidebarOpen']),
    ...mapState(['activeId', 'sidebarType', 'boardLists']),
    isWipLimitsOn() {
      return this.glFeatures.wipLimits && this.isIssueBoard;
    },
    queryVariables() {
      return {
        ...(this.isIssueBoard && {
          isGroup: this.isGroupBoard,
          isProject: !this.isGroupBoard,
        }),
        fullPath: this.fullPath,
        boardId: this.boardId,
        filters: this.filterParams,
        listId: this.activeListId,
      };
    },
    activeListId() {
      return this.isApolloBoard ? this.listId : this.activeId;
    },
    activeList() {
      return this.isApolloBoard ? this.list : this.boardLists[this.activeId] || {};
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
      if (this.isApolloBoard) {
        return Boolean(this.listId);
      }
      return this.sidebarType === LIST && this.isSidebarOpen;
    },
    isLoading() {
      return this.isApolloBoard && this.$apollo.queries.list.loading;
    },
  },
  created() {
    eventHub.$on('sidebar.closeAll', this.unsetActiveListId);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.closeAll', this.unsetActiveListId);
  },
  methods: {
    ...mapActions(['unsetActiveId', 'removeList']),
    handleModalPrimary() {
      this.deleteBoard();
    },
    showScopedLabels(label) {
      return this.scopedLabelsAvailable && isScopedLabel(label);
    },
    deleteBoard() {
      this.track('click_button', { label: 'remove_list' });
      this.removeList(this.activeId);
      this.unsetActiveListId();
    },
    unsetActiveListId() {
      if (this.isApolloBoard) {
        this.$emit('unsetActiveId');
      } else {
        this.unsetActiveId();
      }
    },
  },
};
</script>

<template>
  <mounting-portal mount-to="#js-right-sidebar-portal" name="board-settings-sidebar" append>
    <gl-drawer
      v-bind="$attrs"
      class="js-board-settings-sidebar gl-absolute"
      :open="showSidebar"
      variant="sidebar"
      @close="unsetActiveListId"
    >
      <template #title>
        <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">
          {{ $options.listSettingsText }}
        </h2>
        <gl-loading-icon v-if="isLoading" />
      </template>
      <template v-if="!isLoading" #header>
        <div v-if="canAdminList && activeList.id" class="gl-mt-3">
          <gl-button
            v-gl-modal="$options.modalId"
            variant="danger"
            category="secondary"
            size="small"
            >{{ __('Remove list') }}
          </gl-button>
        </div>
      </template>
      <template v-if="showSidebar && !isLoading">
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
          :active-list-id="activeListId"
        />
      </template>
    </gl-drawer>
    <gl-modal
      :modal-id="$options.modalId"
      :title="$options.i18n.modalAction"
      size="sm"
      :action-primary="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        text: $options.i18n.modalAction,
        attributes: { variant: 'danger' },
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      :action-secondary="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        text: $options.i18n.modalCancel,
        attributes: { variant: 'default' },
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      @primary="handleModalPrimary"
    >
      <p>{{ $options.i18n.modalCopy }}</p>
    </gl-modal>
  </mounting-portal>
</template>
