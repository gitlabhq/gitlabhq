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
        comments: CommentsStore.state,
        loading: false
      };
    },
    computed: {
      buttonText: function () {
        if (!this.canResolve) return;

        if (this.isResolved) {
          return `Resolved by ${this.resolvedByName}`;
        } else {
          return 'Mark as resolved';
        }
      },
      isResolved: function () { return CommentsStore.get(this.discussionId, this.noteId).resolved; },
      resolvedByName: function () { return CommentsStore.get(this.discussionId, this.noteId).user; },
    },
    methods: {
      updateTooltip: function () {
        if (this.canResolve) {
          $(this.$els.button)
            .tooltip('hide')
            .tooltip('fixTitle');
        }
      },
      resolve: function () {
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
          }

          this.$nextTick(this.updateTooltip);
        });
      }
    },
    compiled: function () {
      if (this.canResolve) {
        $(this.$els.button).tooltip({
          container: 'body'
        });
      }
    },
    destroyed: function () {
      CommentsStore.delete(this.discussionId, this.noteId);
    },
    created: function () {
      CommentsStore.create(this.discussionId, this.noteId, this.resolved, this.resolvedBy);
    }
  });
}(window));
