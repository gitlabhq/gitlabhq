/* eslint-disable */
(() => {
  window.gl = window.gl || {};

  gl.issueBoards.BoardNewIssue = Vue.extend({
    props: {
      list: Object,
      showIssueForm: Boolean
    },
    data() {
      return {
        title: '',
        error: false
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
        if (this.title.trim() === '') return;

        this.error = false;

        const labels = this.list.label ? [this.list.label] : [];
        const issue = new ListIssue({
          title: this.title,
          labels
        });

        this.list.newIssue(issue)
          .then((data) => {
            // Need this because our jQuery very kindly disables buttons on ALL form submissions
            $(this.$els.submitButton).enable();
          })
          .catch(() => {
            // Need this because our jQuery very kindly disables buttons on ALL form submissions
            $(this.$els.submitButton).enable();

            // Remove the issue
            this.list.removeIssue(issue);

            // Show error message
            this.error = true;
            this.showIssueForm = true;
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
