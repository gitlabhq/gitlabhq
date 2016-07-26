((w) => {
  w.ResolveBtn = Vue.extend({
    props: {
      noteId: Number,
      discussionId: String,
      resolved: Boolean,
      namespace: String
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
        this.loading = true;
        ResolveService
          .resolve(this.namespace, this.discussionId, this.noteId, !this.isResolved)
          .then(() => {
            this.loading = false;
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
