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
    },
    data: function () {
      return {
        comments: CommentsStore.state,
        loading: false
      };
    },
    computed: {
      buttonText: function () {
        if (this.isResolved) {
          return "Mark as unresolved";
        } else {
          return "Mark as resolved";
        }
      },
      isResolved: function () { return CommentsStore.get(this.discussionId, this.noteId); },
    },
    methods: {
      updateTooltip: function () {
        $(this.$els.button)
          .tooltip('hide')
          .tooltip('fixTitle');
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
          this.loading = false;

          if (response.status === 200) {
            CommentsStore.update(this.discussionId, this.noteId, !this.isResolved);
          }

          this.$nextTick(this.updateTooltip);
        });
      }
    },
    compiled: function () {
      $(this.$els.button).tooltip();
    },
    destroyed: function () {
      CommentsStore.delete(this.discussionId, this.noteId)
    },
    created: function () {
      CommentsStore.create(this.discussionId, this.noteId, this.resolved)
    }
  });
}(window));
