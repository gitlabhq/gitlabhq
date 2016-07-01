ResolveBtn = Vue.extend
  props:
    noteId: Number
    resolved: Boolean
  data: -> comments: CommentsStore.state
  computed:
    buttonText: ->
      if this.comments[this.noteId] then "Mark as un-resolved" else "Mark as resolved"
    isResolved: -> this.comments[this.noteId]
  methods:
    updateTooltip: ->
      $(this.$el)
        .tooltip('hide')
        .tooltip('fixTitle')
    resolve: ->
      CommentsStore.update(this.noteId, !this.comments[this.noteId])

      this.$nextTick this.updateTooltip
  compiled: ->
    $(this.$el).tooltip()
  created: ->
    CommentsStore.create(this.noteId, this.resolved)

Vue.component 'resolve-btn', ResolveBtn
