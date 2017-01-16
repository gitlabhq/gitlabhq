/* eslint-disable comma-dangle, no-unused-vars */
/* global Vue */
/* global ListIssue */

(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};

  gl.issueBoards.BoardNewIssue = Vue.extend({
    template: `
      <div class="card board-new-issue-form">
        <form @submit="submit($event)">
          <div
              class="flash-container"
              v-if="error">
            <div class="flash-alert">
              An error occured. Please try again.
            </div>
          </div>
          <label
            class="label-light"
            :for="list.id + '-title'">
            Title
          </label>
          <input
            class="form-control"
            type="text"
            v-model="title"
            ref="input"
            :id="list.id + '-title'" />
          <div class="clearfix prepend-top-10">
            <button
              class="btn btn-success pull-left"
              type="submit"
              :disabled="title === ''"
              ref="submit-button">
              Submit issue
            </button>
            <button
              class="btn btn-default pull-right"
              type="button"
              @click="cancel">
              Cancel
            </button>
          </div>
        </form>
      </div>
    `,
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
            Store.detail.list = this.list;
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
