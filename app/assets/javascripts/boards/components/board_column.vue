<script>
import Sortable from 'sortablejs';
import isWipLimitsOn from 'ee_else_ce/boards/mixins/is_wip_limits';
import Tooltip from '~/vue_shared/directives/tooltip';
import EmptyComponent from '~/vue_shared/components/empty_component';
import BoardBlankState from './board_blank_state.vue';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import BoardList from './board_list.vue';
import boardsStore from '../stores/boards_store';
import eventHub from '../eventhub';
import { getBoardSortableDefaultOptions, sortableEnd } from '../mixins/sortable_default_options';
import { ListType } from '../constants';

export default {
  components: {
    BoardPromotionState: EmptyComponent,
    BoardBlankState,
    BoardListHeader,
    BoardList,
  },
  directives: {
    Tooltip,
  },
  mixins: [isWipLimitsOn],
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
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
    groupId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      detailIssue: boardsStore.detail,
      filter: boardsStore.filter,
    };
  },
  computed: {
    showBoardListAndBoardInfo() {
      return this.list.type !== ListType.blank && this.list.type !== ListType.promotion;
    },
    uniqueKey() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `boards.${this.boardId}.${this.list.type}.${this.list.id}`;
    },
  },
  watch: {
    filter: {
      handler() {
        this.list.page = 1;
        this.list.getIssues(true).catch(() => {
          // TODO: handle request error
        });
      },
      deep: true,
    },
  },
  mounted() {
    const instance = this;

    const sortableOptions = getBoardSortableDefaultOptions({
      disabled: this.disabled,
      group: 'boards',
      draggable: '.is-draggable',
      handle: '.js-board-handle',
      onEnd(e) {
        sortableEnd();

        const sortable = this;

        if (e.newIndex !== undefined && e.oldIndex !== e.newIndex) {
          const order = sortable.toArray();
          const list = boardsStore.findList('id', parseInt(e.item.dataset.id, 10));

          instance.$nextTick(() => {
            boardsStore.moveList(list, order);
          });
        }
      },
    });

    Sortable.create(this.$el.parentNode, sortableOptions);
  },
  methods: {
    showListNewIssueForm(listId) {
      eventHub.$emit('showForm', listId);
    },
  },
};
</script>

<template>
  <div
    :class="{
      'is-draggable': !list.preset,
      'is-expandable': list.isExpandable,
      'is-collapsed': !list.isExpanded,
      'board-type-assignee': list.type === 'assignee',
    }"
    :data-id="list.id"
    class="board gl-h-full gl-px-3 gl-vertical-align-top gl-white-space-normal"
    data-qa-selector="board_list"
  >
    <div
      class="board-inner gl-display-flex gl-flex-direction-column gl-relative gl-h-full gl-rounded-base"
    >
      <board-list-header
        :can-admin-list="canAdminList"
        :list="list"
        :disabled="disabled"
        :board-id="boardId"
      />
      <board-list
        v-if="showBoardListAndBoardInfo"
        ref="board-list"
        :disabled="disabled"
        :group-id="groupId || null"
        :issue-link-base="issueLinkBase"
        :issues="list.issues"
        :list="list"
        :loading="list.loading"
        :root-path="rootPath"
      />
      <board-blank-state v-if="canAdminList && list.id === 'blank'" />

      <!-- Will be only available in EE -->
      <board-promotion-state v-if="list.id === 'promotion'" />
    </div>
  </div>
</template>
