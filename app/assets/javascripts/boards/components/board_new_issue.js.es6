(() => {
  window.gl = window.gl || {};

  gl.issueBoards.BoardNewIssue = Vue.extend({
    props: {
      list: Object,
      showIssueForm: Boolean
    },
    data() {
      return {
        title: ''
      };
    },
    watch: {
      showIssueForm () {
        this.$els.input.focus();
      }
    },
    methods: {
      submit(e) {
        e.preventDefault();
        const labels = this.list.label ? [this.list.label] : [];
        const issue = new ListIssue({
          title: this.title,
          labels
        });

        this.list.newIssue(issue)
          .then(() => {
            // Need this because our jQuery very kindly disables buttons on ALL form submissions
            $(this.$els.submitButton).enable();
          });

        this.cancel();
      },
      cancel() {
        this.showIssueForm = false;
        this.title = '';
      }
    }
  });
})();
