/* global Sortable */
import boardList from './board_list';
import boardBlankState from './board_blank_state';
import boardDelete from './board_delete';
import eventHub from '../eventhub';

export default {
  name: 'Board',
  props: {
    list: {
      type: Object,
      required: true,
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
    store: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      detailIssue: this.store.detail,
      canAdminIssue: this.store.state.canAdminIssue,
      canAdminList: this.store.state.canAdminList,
      filter: this.store.filter,
    };
  },
  components: {
    boardList,
    boardDelete,
    boardBlankState,
  },
  methods: {
    showNewIssueForm() {
      eventHub.$emit(`toggle-issue-form-${this.list.id}`);
    },
  },
  watch: {
    filter: {
      handler() {
        this.list.page = 1;
        this.list.getIssues(true);
      },
      deep: true,
    },
    detailIssue: {
      handler() {
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
              scrollLeft: right,
            }, this.sortableOptions.animation);
          } else if (left > 0) {
            $(boardsList).animate({
              scrollLeft: offsetLeft,
            }, this.sortableOptions.animation);
          }
        }
      },
      deep: true,
    },
  },
  mounted() {
    this.sortableOptions = gl.issueBoards.getBoardSortableDefaultOptions({
      disabled: this.disabled,
      group: 'boards',
      draggable: '.is-draggable',
      handle: '.js-board-handle',
      onEnd: (e) => {
        gl.issueBoards.onEnd();

        if (e.newIndex !== undefined && e.oldIndex !== e.newIndex) {
          const order = this.sortable.toArray();
          const list = this.store.findList('id', parseInt(e.item.dataset.id, 10));

          this.$nextTick(() => {
            this.store.moveList(list, order);
          });
        }
      },
    });

    this.sortable = Sortable.create(this.$el.parentNode, this.sortableOptions);
  },
  template: `
    <div
      class="board"
      :class="{ 'is-draggable': !list.preset }"
      :data-id="list.id">
      <div class="board-inner">
        <header
          class="board-header"
          :class="{ 'has-border': list.label }"
          :style="{ borderTopColor: (list.label ? list.label.color : null) }">
          <h3
            class="board-title js-board-handle"
            :class="{ 'user-can-drag': (!disabled && !list.preset) }">
            <span
              class="has-tooltip"
              :title="(list.label ? list.label.description : '')"
              data-container="body"
              data-placement="bottom">
              {{ list.title }}
            </span>
            <div
              class="board-issue-count-holder pull-right clearfix"
              v-if="list.type !== 'blank'">
              <span
                class="board-issue-count pull-left"
                :class="{ 'has-btn': list.type !== 'closed' && !disabled }">
                {{ list.issuesSize }}
              </span>
              <button
                class="btn btn-small btn-default pull-right has-tooltip"
                type="button"
                @click="showNewIssueForm"
                v-if="canAdminIssue && list.type !== 'closed'"
                aria-label="Add an issue"
                title="Add an issue"
                data-placement="top"
                data-container="body">
                <i
                  class="fa fa-plus"
                  aria-hidden="true">
                </i>
              </button>
            </div>
            <board-delete
              :list="list"
              v-if="canAdminList && !list.preset && list.id" />
          </h3>
        </header>
        <board-list
          v-if="list.type !== 'blank'"
          :store="store"
          :list="list"
          :issues="list.issues"
          :loading="list.loading"
          :disabled="disabled"
          :issue-link-base="issueLinkBase"
          :root-path="rootPath"
          ref="board-list" />
        <board-blank-state
          v-if="canAdminList && list.id === 'blank'"
          :store="store" />
      </div>
    </div>
  `,
};
