<script>
import { mapGetters, mapActions } from 'vuex';
import Sortable from 'sortablejs';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import EmptyComponent from '~/vue_shared/components/empty_component';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BoardList from './board_list.vue';
import BoardListNew from './board_list_new.vue';
import boardsStore from '../stores/boards_store';
import eventHub from '../eventhub';
import { getBoardSortableDefaultOptions, sortableEnd } from '../mixins/sortable_default_options';
import { ListType } from '../constants';

export default {
  components: {
    BoardPromotionState: EmptyComponent,
    BoardListHeader,
    BoardList: gon.features?.graphqlBoardLists ? BoardListNew : BoardList,
  },
  mixins: [glFeatureFlagMixin()],
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
  inject: {
    boardId: {
      default: '',
    },
  },
  data() {
    return {
      detailIssue: boardsStore.detail,
      filter: boardsStore.filter,
    };
  },
  computed: {
    ...mapGetters(['getIssuesByList']),
    showBoardListAndBoardInfo() {
      return this.list.type !== ListType.promotion;
    },
    uniqueKey() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `boards.${this.boardId}.${this.list.type}.${this.list.id}`;
    },
    listIssues() {
      if (!this.glFeatures.graphqlBoardLists) {
        return this.list.issues;
      }
      return this.getIssuesByList(this.list.id);
    },
    shouldFetchIssues() {
      return this.glFeatures.graphqlBoardLists && this.list.type !== ListType.blank;
    },
  },
  watch: {
    filter: {
      handler() {
        if (this.shouldFetchIssues) {
          this.fetchIssuesForList({ listId: this.list.id });
        } else {
          this.list.page = 1;
          this.list.getIssues(true).catch(() => {
            // TODO: handle request error
          });
        }
      },
      deep: true,
    },
  },
  mounted() {
    if (this.shouldFetchIssues) {
      this.fetchIssuesForList({ listId: this.list.id });
    }

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
    ...mapActions(['fetchIssuesForList']),
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
    class="board gl-display-inline-block gl-h-full gl-px-3 gl-vertical-align-top gl-white-space-normal"
    data-qa-selector="board_list"
  >
    <div
      class="board-inner gl-display-flex gl-flex-direction-column gl-relative gl-h-full gl-rounded-base"
    >
      <board-list-header :can-admin-list="canAdminList" :list="list" :disabled="disabled" />
      <board-list
        v-if="showBoardListAndBoardInfo"
        ref="board-list"
        :disabled="disabled"
        :issues="listIssues"
        :list="list"
      />

      <!-- Will be only available in EE -->
      <board-promotion-state v-if="list.id === 'promotion'" />
    </div>
  </div>
</template>
