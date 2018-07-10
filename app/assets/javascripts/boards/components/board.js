/* eslint-disable comma-dangle */

import Sortable from 'sortablejs';
import Vue from 'vue';
import { n__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import AccessorUtilities from '../../lib/utils/accessor';
import boardList from './board_list.vue';
import BoardBlankState from './board_blank_state.vue';
import './board_delete';

const Store = gl.issueBoards.BoardsStore;

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

gl.issueBoards.Board = Vue.extend({
  components: {
    boardList,
    'board-delete': gl.issueBoards.BoardDelete,
    BoardBlankState,
    Icon,
  },
  directives: {
    Tooltip,
  },
  props: {
    list: {
      type: Object,
      default: () => ({}),
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
  data () {
    return {
      detailIssue: Store.detail,
      filter: Store.filter,
    };
  },
  computed: {
    counterTooltip() {
      const { issuesSize } = this.list;
      return `${n__('%d issue', '%d issues', issuesSize)}`;
    },
  },
  watch: {
    filter: {
      handler() {
        this.list.page = 1;
        this.list.getIssues(true)
          .catch(() => {
            // TODO: handle request error
          });
      },
      deep: true,
    }
  },
  mounted () {
    this.sortableOptions = gl.issueBoards.getBoardSortableDefaultOptions({
      disabled: this.disabled,
      group: 'boards',
      draggable: '.is-draggable',
      handle: '.js-board-handle',
      onEnd: (e) => {
        gl.issueBoards.onEnd();

        if (e.newIndex !== undefined && e.oldIndex !== e.newIndex) {
          const order = this.sortable.toArray();
          const list = Store.findList('id', parseInt(e.item.dataset.id, 10));

          this.$nextTick(() => {
            Store.moveList(list, order);
          });
        }
      }
    });

    this.sortable = Sortable.create(this.$el.parentNode, this.sortableOptions);
  },
  created() {
    if (this.list.isExpandable && AccessorUtilities.isLocalStorageAccessSafe()) {
      const isCollapsed = localStorage.getItem(`boards.${this.boardId}.${this.list.type}.expanded`) === 'false';

      this.list.isExpanded = !isCollapsed;
    }
  },
  methods: {
    showNewIssueForm() {
      this.$refs['board-list'].showIssueForm = !this.$refs['board-list'].showIssueForm;
    },
    toggleExpanded(e) {
      if (this.list.isExpandable && !e.target.classList.contains('js-no-trigger-collapse')) {
        this.list.isExpanded = !this.list.isExpanded;

        if (AccessorUtilities.isLocalStorageAccessSafe()) {
          localStorage.setItem(`boards.${this.boardId}.${this.list.type}.expanded`, this.list.isExpanded);
        }
      }
    },
  },
  template: '#js-board-template',
});
