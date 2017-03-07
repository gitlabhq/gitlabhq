/* eslint-disable comma-dangle, space-before-function-paren, one-var */
/* global Vue */
/* global Sortable */

require('./board_blank_state');
require('./board_delete');
require('./board_list');

(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.Board = Vue.extend({
    template: '#js-board-template',
    components: {
      'board-list': gl.issueBoards.BoardList,
      'board-delete': gl.issueBoards.BoardDelete,
      'board-blank-state': gl.issueBoards.BoardBlankState
    },
    props: {
      list: Object,
      disabled: Boolean,
      issueLinkBase: String,
      rootPath: String,
    },
    data () {
      return {
        detailIssue: Store.detail,
        filters: Store.state.filters,
      };
    },
    watch: {
      filters: {
        handler () {
          this.list.page = 1;
          this.list.getIssues(true);
        },
        deep: true
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
    methods: {
      showNewIssueForm() {
        this.$refs['board-list'].showIssueForm = !this.$refs['board-list'].showIssueForm;
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
  });
})();
