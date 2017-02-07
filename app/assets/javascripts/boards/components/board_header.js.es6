/* global Vue */
const boardDelete = require('./board_delete');

module.exports = Vue.extend({
  name: 'board-header',
  template: `
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
            :class="{ 'has-btn': list.type !== 'done' && !disabled }">
            {{ list.issuesSize }}
          </span>
          <button
            class="btn btn-small btn-default pull-right has-tooltip"
            type="button"
            @click="showNewIssueForm"
            v-if ="canAdminIssue && list.type !== 'done'"
            aria-label="Add an issue"
            title="Add an issue"
            data-placement="top"
            data-container="body">
            <i class="fa fa-plus"></i>
          </button>
        </div>
        <board-delete
          :list="list"
          v-if="canAdminList && !list.preset && list.id">
        </board-delete>
      </h3>
    </header>
  `,
  components: {
    boardDelete,
  },
  props: [
    'disabled', 'list', 'canAdminList', 'canAdminIssue',
  ],
  methods: {
    showNewIssueForm() {
      this.$parent.$refs['board-list'].showIssueForm = !this.$parent.$refs['board-list'].showIssueForm;
    },
  },
});
