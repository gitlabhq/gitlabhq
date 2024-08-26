<script>
import produce from 'immer';
import { GlButton, GlDrawer, GlLabel, GlModal, GlModalDirective } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import {
  ListType,
  ListTypeTitles,
  listsQuery,
  deleteListQueries,
} from 'ee_else_ce/boards/constants';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { setError } from '../graphql/cache_updates';

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
  inject: ['boardType', 'canAdminList', 'issuableType', 'scopedLabelsAvailable', 'isIssueBoard'],
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
    list: {
      type: Object,
      required: false,
      default: () => {},
    },
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      ListType,
    };
  },
  modalId: 'board-settings-sidebar-modal',
  computed: {
    isWipLimitsOn() {
      return this.glFeatures.wipLimits && this.isIssueBoard;
    },
    activeListId() {
      return this.listId;
    },
    activeList() {
      return this.list;
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
      return Boolean(this.listId);
    },
  },
  methods: {
    handleModalPrimary() {
      this.deleteBoardList();
    },
    showScopedLabels(label) {
      return this.scopedLabelsAvailable && isScopedLabel(label);
    },
    deleteBoardList() {
      this.track('click_button', { label: 'remove_list' });
      this.deleteList(this.activeListId);
      this.unsetActiveListId();
    },
    unsetActiveListId() {
      this.$emit('unsetActiveId');
    },
    async deleteList(listId) {
      try {
        await this.$apollo.mutate({
          mutation: deleteListQueries[this.issuableType].mutation,
          variables: {
            listId,
          },
          update: (store) => {
            store.updateQuery(
              { query: listsQuery[this.issuableType].query, variables: this.queryVariables },
              (sourceData) =>
                produce(sourceData, (draftData) => {
                  draftData[this.boardType].board.lists.nodes = draftData[
                    this.boardType
                  ].board.lists.nodes.filter((list) => list.id !== listId);
                }),
            );
          },
        });
      } catch (error) {
        setError({
          error,
          message: s__('Boards|An error occurred while deleting the list. Please try again.'),
        });
      }
    },
  },
};
</script>

<template>
  <mounting-portal mount-to="#js-right-sidebar-portal" name="board-settings-sidebar" append>
    <gl-drawer
      v-bind="$attrs"
      class="js-board-settings-sidebar boards-sidebar"
      :open="showSidebar"
      variant="sidebar"
      @close="unsetActiveListId"
    >
      <template #title>
        <h2 class="gl-my-0 gl-text-size-h2 gl-leading-24">
          {{ $options.listSettingsText }}
        </h2>
      </template>
      <template #header>
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
      <template v-if="showSidebar">
        <div v-if="boardListType === ListType.label">
          <label class="js-list-label gl-block">{{ listTypeTitle }}</label>
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
