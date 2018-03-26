/* eslint-disable comma-dangle, space-before-function-paren, one-var */

import $ from 'jquery';
import Sortable from 'vendor/Sortable';
import Vue from 'vue';
import AccessorUtilities from '../../lib/utils/accessor';
import boardList from './board_list.vue';
import boardBlankState from './board_blank_state';
import './board_delete';

const Store = gl.issueBoards.BoardsStore;

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

gl.issueBoards.Board = Vue.extend({
  components: {
    boardList,
    'board-delete': gl.issueBoards.BoardDelete,
    boardBlankState,
  },
  props: {
    list: Object,
    disabled: Boolean,
    issueLinkBase: String,
    rootPath: String,
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
    },
    detailIssue: {
      handler () {
        if (!Object.keys(this.detailIssue.issue).length) return;

        const issue = this.list.findIssue(this.detailIssue.issue.id);

        if (issue) {
          const offsetLeft = this.$el.offsetLeft;
          const boardsList = document.querySelectorAll('.boards-list')[0];
          const left = boardsList.scrollLeft - offsetLeft;
          let right = (offsetLeft + this.$el.offsetWidth);

          if (window.innerWidth > 768 && boardsList.classList.contains('is-compact')) {
            // -290 here because width of boardsList is animating so therefore
            // getting the width here is incorrect
            // 290 is the width of the sidebar
            right -= (boardsList.offsetWidth - 290);
          } else {
            right -= boardsList.offsetWidth;
          }

          if (right - boardsList.scrollLeft > 0) {
            $(boardsList).animate({
              scrollLeft: right
            }, this.sortableOptions.animation);
          } else if (left > 0) {
            $(boardsList).animate({
              scrollLeft: offsetLeft
            }, this.sortableOptions.animation);
          }
        }
      },
      deep: true
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
