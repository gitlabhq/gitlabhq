(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardSidebar = Vue.extend({
    data() {
      return {
        issue: Store.state.detailIssue
      };
    },
    ready: function () {
      console.log(this.issue);
    },
    watch: {
      issue: {
        handler () {
          console.log('a');
        },
        deep: true
      }
    }
  });
})();
