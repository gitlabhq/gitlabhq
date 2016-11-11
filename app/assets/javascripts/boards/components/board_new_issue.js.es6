/* eslint-disable */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};

  gl.issueBoards.BoardNewIssue = Vue.extend({
    props: {
      list: Object,
    },
    data() {
      return {
        title: '',
        error: false
      };
    },
    methods: {
      submit(e) {
        e.preventDefault();
        if (this.title.trim() === '') return;

        this.error = false;

        const labels = this.list.label ? [this.list.label] : [];
        const issue = new ListIssue({
          title: this.title,
          labels,
          subscribed: true
        });

        this.list.newIssue(issue)
          .then((data) => {
            // Need this because our jQuery very kindly disables buttons on ALL form submissions
            $(this.$refs.submitButton).enable();

            Store.detail.issue = issue;
          })
          .catch(() => {
            // Need this because our jQuery very kindly disables buttons on ALL form submissions
            $(this.$refs.submitButton).enable();

            // Remove the issue
            this.list.removeIssue(issue);

            // Show error message
            this.error = true;
          });

        this.cancel();
      },
      cancel() {
        this.title = '';
        this.$parent.showIssueForm = false;
      }
    },
    mounted() {
      this.$refs.input.focus();
    },
  });
})();
