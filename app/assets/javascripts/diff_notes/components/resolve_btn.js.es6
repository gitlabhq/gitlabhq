((w) => {
  w.ResolveBtn = Vue.extend({
    mixins: [
      ButtonMixins
    ],
    props: {
      noteId: Number,
      discussionId: String,
      resolved: Boolean,
      namespacePath: String,
      projectPath: String,
      canResolve: Boolean,
      resolvedBy: String
    },
    data: function () {
      return {
        discussions: CommentsStore.state,
        loading: false
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
      note: function () {
        if (this.discussion) {
          return this.discussion.getNote(this.noteId);
        }
      },
      buttonText: function () {
        if (this.isResolved) {
          return `Resolved by ${this.resolvedByName}`;
        } else if (this.canResolve) {
          return 'Mark as resolved';
        }
      },
      isResolved: function () {
        if (this.note) {
          return this.note.resolved;
        }
      },
      resolvedByName: function () {
        return this.note.resolved_by;
      },
    },
    methods: {
      updateTooltip: function () {
        $(this.$els.button)
          .tooltip('hide')
          .tooltip('fixTitle');
      },
      resolve: function () {
        if (!this.canResolve) return;

        let promise;
        this.loading = true;

        if (this.isResolved) {
          promise = ResolveService
            .unresolve(this.namespace, this.noteId);
        } else {
          promise = ResolveService
            .resolve(this.namespace, this.noteId);
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

          this.$nextTick(this.updateTooltip);
        });
      }
    },
    compiled: function () {
      $(this.$els.button).tooltip({
        container: 'body'
      });
    },
    beforeDestroy: function () {
      CommentsStore.delete(this.discussionId, this.noteId);
    },
    created: function () {
      CommentsStore.create(this.discussionId, this.noteId, this.canResolve, this.resolved, this.resolvedBy);
    }
  });
})(window);
