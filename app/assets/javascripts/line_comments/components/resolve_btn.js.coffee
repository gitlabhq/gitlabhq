@ResolveBtn = Vue.extend
  props:
    noteId: Number
    resolved: Boolean
    namespace: String
  data: ->
    comments: CommentsStore.state
    loading: false
  computed:
    buttonText: ->
      if this.isResolved then "Mark as un-resolved" else "Mark as resolved"
    isResolved: -> this.comments[this.noteId]
  methods:
    updateTooltip: ->
      $(this.$els.button)
        .tooltip('hide')
        .tooltip('fixTitle')
    resolve: ->
      this.loading = true
      ResolveService
        .resolve(this.namespace, this.noteId, !this.isResolved)
        .then =>
          this.loading = false
          this.$nextTick this.updateTooltip
  compiled: ->
    $(this.$els.button).tooltip()
  destroyed: ->
    CommentsStore.delete(this.noteId)
  created: ->
    CommentsStore.create(this.noteId, this.resolved)
