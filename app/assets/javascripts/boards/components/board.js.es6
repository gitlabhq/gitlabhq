/* eslint-disable */
//= require ./board_blank_state
//= require ./board_delete
//= require ./board_list

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
      issueLinkBase: String
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
            const boardsList = document.querySelectorAll('.boards-list')[0];
            const right = (this.$el.offsetLeft + this.$el.offsetWidth) - boardsList.offsetWidth;
            const left = boardsList.scrollLeft - this.$el.offsetLeft;

            if (right - boardsList.scrollLeft > 0) {
              boardsList.scrollLeft = right;
            } else if (left > 0) {
              boardsList.scrollLeft = this.$el.offsetLeft;
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
      const options = gl.issueBoards.getBoardSortableDefaultOptions({
        disabled: this.disabled,
        group: 'boards',
        draggable: '.is-draggable',
        handle: '.js-board-handle',
        onEnd: (e) => {
          gl.issueBoards.onEnd();

          if (e.newIndex !== undefined && e.oldIndex !== e.newIndex) {
            const order = this.sortable.toArray(),
                  list = Store.findList('id', parseInt(e.item.dataset.id));

            this.$nextTick(() => {
              Store.moveList(list, order);
            });
          }
        }
      });

      this.sortable = Sortable.create(this.$el.parentNode, options);
    },
  });
})();
