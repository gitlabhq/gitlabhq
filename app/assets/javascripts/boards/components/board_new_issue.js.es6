(() => {
  window.gl = window.gl || {};

  gl.issueBoards.BoardNewIssue = Vue.extend({
    props: {
      showIssueForm: Boolean
    },
    data() {
      return {
        title: ''
      };
    },
    methods: {
      submit(e) {
        e.preventDefault();

        this.title = '';
      },
      cancel() {
        this.showIssueForm = false;
      }
    }
  });
})();
