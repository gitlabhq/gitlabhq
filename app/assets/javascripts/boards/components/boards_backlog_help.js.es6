/* global Cookies */
const Vue = require('vue');

const Store = gl.issueBoards.BoardsStore;
const ModalStore = gl.issueBoards.ModalStore;

module.exports = Vue.extend({
  mixins: [gl.issueBoards.ModalMixins],
  data() {
    return ModalStore.store;
  },
  methods: {
    closeHelp(openModal) {
      Store.state.helpHidden = true;
      Cookies.set('boards_backlog_help_hidden', true);

      if (openModal) {
        this.toggleModal(true);
      }
    },
  },
  computed: {
    disabled() {
      return !Store.state.lists
        .filter(list => list.type !== 'blank' && list.type !== 'done').length;
    },
  },
  template: `
    <div class="boards-backlog-help">
      <h4>
        We removed the Backlog
        <button
          type="button"
          class="close"
          aria-label="Close backlog help"
          @click="closeHelp(false)">
          <i class="fa fa-times"></i>
        </button>
      </h4>
      <p>
        <a href="http://docs.gitlab.com/ce/user/project/issue_board.html">Read the docs</a> to find out why
      </p>
      <p>
        You can populate your board using this button
      </p>
      <div class="text-center">
        <button
          class="btn btn-success"
          type="button"
          @click="closeHelp(true)">
          Add issues
        </button>
      </div>
    </div>
  `,
});
