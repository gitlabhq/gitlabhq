<script>
import { mapState } from 'vuex';
import { GlAlert } from '@gitlab/ui';
import BoardColumn from 'ee_else_ce/boards/components/board_column.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    BoardColumn,
    EpicsSwimlanes: () => import('ee_component/boards/components/epics_swimlanes.vue'),
    GlAlert,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    lists: {
      type: Array,
      required: true,
    },
    canAdminList: {
      type: Boolean,
      required: true,
    },
    groupId: {
      type: Number,
      required: false,
      default: null,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    issueLinkBase: {
      type: String,
      required: true,
    },
    rootPath: {
      type: String,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['isShowingEpicsSwimlanes', 'boardLists', 'error']),
    isSwimlanesOn() {
      return this.glFeatures.boardsWithSwimlanes && this.isShowingEpicsSwimlanes;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" :dismissible="false">
      {{ error }}
    </gl-alert>
    <div
      v-if="!isSwimlanesOn"
      class="boards-list gl-w-full gl-py-5 gl-px-3 gl-white-space-nowrap"
      data-qa-selector="boards_list"
    >
      <board-column
        v-for="list in lists"
        :key="list.id"
        ref="board"
        :can-admin-list="canAdminList"
        :group-id="groupId"
        :list="list"
        :disabled="disabled"
        :issue-link-base="issueLinkBase"
        :root-path="rootPath"
        :board-id="boardId"
      />
    </div>
    <epics-swimlanes
      v-else
      ref="swimlanes"
      :lists="boardLists"
      :can-admin-list="canAdminList"
      :disabled="disabled"
      :board-id="boardId"
      :group-id="groupId"
      :root-path="rootPath"
    />
  </div>
</template>
