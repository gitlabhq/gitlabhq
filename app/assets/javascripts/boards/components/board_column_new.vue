<script>
import { mapGetters, mapActions, mapState } from 'vuex';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header_new.vue';
import BoardList from './board_list_new.vue';
import { isListDraggable } from '../boards_util';

export default {
  components: {
    BoardListHeader,
    BoardList,
  },
  inject: {
    boardId: {
      default: '',
    },
  },
  props: {
    list: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['filterParams']),
    ...mapGetters(['getIssuesByList']),
    listIssues() {
      return this.getIssuesByList(this.list.id);
    },
    isListDraggable() {
      return isListDraggable(this.list);
    },
  },
  watch: {
    filterParams: {
      handler() {
        this.fetchIssuesForList({ listId: this.list.id });
      },
      deep: true,
      immediate: true,
    },
  },
  methods: {
    ...mapActions(['fetchIssuesForList']),
  },
};
</script>

<template>
  <div
    :class="{
      'is-draggable': isListDraggable,
      'is-collapsed': list.collapsed,
      'board-type-assignee': list.listType === 'assignee',
    }"
    :data-id="list.id"
    class="board gl-display-inline-block gl-h-full gl-px-3 gl-vertical-align-top gl-white-space-normal is-expandable"
    data-qa-selector="board_list"
  >
    <div
      class="board-inner gl-display-flex gl-flex-direction-column gl-relative gl-h-full gl-rounded-base"
    >
      <board-list-header :can-admin-list="canAdminList" :list="list" :disabled="disabled" />
      <board-list
        ref="board-list"
        :disabled="disabled"
        :issues="listIssues"
        :list="list"
        :can-admin-list="canAdminList"
      />
    </div>
  </div>
</template>
