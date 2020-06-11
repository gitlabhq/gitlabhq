<script>
import { mapState } from 'vuex';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BoardColumn from 'ee_else_ce/boards/components/board_column.vue';
import EpicsSwimlanes from 'ee_component/boards/components/epics_swimlanes.vue';

export default {
  components: {
    BoardColumn,
    EpicsSwimlanes,
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
    ...mapState(['isShowingEpicsSwimlanes']),
    isSwimlanesOn() {
      return this.glFeatures.boardsWithSwimlanes && this.isShowingEpicsSwimlanes;
    },
  },
};
</script>

<template>
  <div>
    <div
      v-if="!isSwimlanesOn"
      class="boards-list w-100 py-3 px-2 text-nowrap"
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
      :lists="lists"
      :can-admin-list="canAdminList"
      :group-id="groupId"
      :disabled="disabled"
      :issue-link-base="issueLinkBase"
      :root-path="rootPath"
      :board-id="boardId"
    />
  </div>
</template>
