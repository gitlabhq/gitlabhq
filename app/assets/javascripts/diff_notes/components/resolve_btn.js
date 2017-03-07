/* eslint-disable comma-dangle, object-shorthand, func-names, quote-props, no-else-return, camelcase, no-new, max-len */
/* global CommentsStore */
/* global ResolveService */
/* global Flash */
const Vue = require('vue');

(() => {
  const ResolveBtn = Vue.extend({
    props: {
      noteId: Number,
      discussionId: String,
      resolved: Boolean,
      canResolve: Boolean,
      resolvedBy: String
    },
    data: function () {
      return {
        discussions: CommentsStore.state,
        loading: false,
        note: {},
      };
    },
    watch: {
      'discussions': {
        handler: 'updateTooltip',
        deep: true
      }
    },
    computed: {
      discussion: function () {
        return this.discussions[this.discussionId];
      },
      buttonText: function () {
        if (this.isResolved) {
          return `Resolved by ${this.resolvedByName}`;
        } else if (this.canResolve) {
          return 'Mark as resolved';
        } else {
          return 'Unable to resolve';
        }
      },
      isResolved: function () {
        if (this.note) {
          return this.note.resolved;
        } else {
          return false;
        }
      },
      resolvedByName: function () {
        return this.note.resolved_by;
      },
    },
    methods: {
      updateTooltip: function () {
        this.$nextTick(() => {
          $(this.$refs.button)
            .tooltip('hide')
            .tooltip('fixTitle');
        });
      },
      resolve: function () {
        if (!this.canResolve) return;

        let promise;
        this.loading = true;

        if (this.isResolved) {
          promise = ResolveService
            .unresolve(this.noteId);
        } else {
          promise = ResolveService
            .resolve(this.noteId);
        }

        promise.then((response) => {
          this.loading = false;

          if (response.status === 200) {
            const data = response.json();
            const resolved_by = data ? data.resolved_by : null;

            CommentsStore.update(this.discussionId, this.noteId, !this.isResolved, resolved_by);
            this.discussion.updateHeadline(data);
          } else {
            new Flash('An error occurred when trying to resolve a comment. Please try again.', 'alert');
          }

          this.updateTooltip();
        });
      }
    },
    mounted: function () {
      $(this.$refs.button).tooltip({
        container: 'body'
      });
    },
    beforeDestroy: function () {
      CommentsStore.delete(this.discussionId, this.noteId);
    },
    created: function () {
      CommentsStore.create(this.discussionId, this.noteId, this.canResolve, this.resolved, this.resolvedBy);

      this.note = this.discussion.getNote(this.noteId);
    }
  });

  Vue.component('resolve-btn', ResolveBtn);
})();
