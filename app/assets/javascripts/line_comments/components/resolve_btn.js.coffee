@ResolveBtn = Vue.extend
  props:
    noteId: Number
    resolved: Boolean
    endpoint: String
  data: ->
    comments: CommentsStore.state
    loading: false
  computed:
    buttonText: ->
      if this.comments[this.noteId] then "Mark as un-resolved" else "Mark as resolved"
    isResolved: -> this.comments[this.noteId]
  methods:
    updateTooltip: ->
      $(this.$els.button)
        .tooltip('hide')
        .tooltip('fixTitle')
    resolve: ->
      this.$set('loading', true)
      ResolveService
        .resolve(this.endpoint, !this.isResolved)
        .done =>
          this.$set('loading', false)
          CommentsStore.update(this.noteId, !this.isResolved)

          this.$nextTick this.updateTooltip
        .always =>
          this.$set('loading', false)
  compiled: ->
    $(this.$els.button).tooltip()
  destroyed: ->
    CommentsStore.delete(this.noteId)
  created: ->
    CommentsStore.create(this.noteId, this.resolved)
