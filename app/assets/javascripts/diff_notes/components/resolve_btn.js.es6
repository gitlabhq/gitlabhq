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
    computed: {
      buttonText: function () {
        if (this.isResolved) {
          return `Resolved by ${this.resolvedByName}`;
        } else if (this.canResolve) {
          return 'Mark as resolved';
        }
      },
      isResolved: function () { return CommentsStore.get(this.discussionId, this.noteId).resolved; },
      resolvedByName: function () { return CommentsStore.get(this.discussionId, this.noteId).user; },
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
          const data = response.data;
          const user = data ? data.resolved_by : null;
          this.loading = false;

          if (response.status === 200) {
            CommentsStore.update(this.discussionId, this.noteId, !this.isResolved, user);

            ResolveService.updateUpdatedHtml(this.discussionId, data);
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
    destroyed: function () {
      CommentsStore.delete(this.discussionId, this.noteId);
    },
    created: function () {
      CommentsStore.create(this.discussionId, this.noteId, this.resolved, this.resolvedBy);
    }
  });
})(window);
