@ResolveBtn = Vue.extend
  props:
    noteId: Number
    discussionId: String
    resolved: Boolean
    namespace: String
  data: ->
    comments: CommentsStore.state
    loading: false
  computed:
    buttonText: ->
      if this.isResolved then "Mark as unresolved" else "Mark as resolved"
    isResolved: -> CommentsStore.get(this.discussionId, this.noteId)
  methods:
    updateTooltip: ->
      $(this.$els.button)
        .tooltip('hide')
        .tooltip('fixTitle')
    resolve: ->
      this.loading = true
      ResolveService
        .resolve(this.namespace, this.discussionId, this.noteId, !this.isResolved)
        .then =>
          this.loading = false
          this.$nextTick this.updateTooltip
  compiled: ->
    $(this.$els.button).tooltip()
  destroyed: ->
    CommentsStore.delete(this.discussionId, this.noteId)
  created: ->
    CommentsStore.create(this.discussionId, this.noteId, this.resolved)
