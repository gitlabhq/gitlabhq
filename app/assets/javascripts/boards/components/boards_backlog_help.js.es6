const Vue = require('vue');
const checkmarkIcon = require('../icons/checkmark');

const Store = gl.issueBoards.BoardsStore;
const ModalStore = gl.issueBoards.ModalStore;

module.exports = Vue.extend({
  mixins: [gl.issueBoards.ModalMixins],
  data() {
    return ModalStore.store;
  },
  computed: {
    disabled() {
      return !Store.state.lists
        .filter(list => list.type !== 'blank' && list.type !== 'done').length;
    },
  },
  template: `
    <div class="boards-backlog-help text-center">
      <h4>
        We moved the Backlog
        <button
          type="button"
          class="close"
          aria-label="Close backlog help"
          @click="toggleModal(false)">
          <i
            class="fa fa-times"
            aria-hidden="true">
          </i>
        </button>
      </h4>
      <div class="backlog-help-icon">${checkmarkIcon}</div>
      <p>
        <a href="http://docs.gitlab.com/ce/user/project/issue_board.html">Read the docs</a> for more details
      </p>
      <p>
        Populate the board using this button
      </p>
      <div class="text-center">
        <button
          class="btn btn-success"
          type="button"
          :disabled="disabled"
          @click="toggleModal(true, false)">
          Add issues
        </button>
      </div>
    </div>
  `,
});
