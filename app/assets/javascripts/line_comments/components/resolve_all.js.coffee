ResolveAll = Vue.extend
  data: ->
    { comments: CommentsStore.state }
  computed:
    resolved: ->
      resolvedCount = 0
      for noteId, resolved of this.comments
        resolvedCount++ if resolved
      resolvedCount
    commentsCount: ->
      Object.keys(this.comments).length
    buttonText: ->
      if this.resolved is this.commentsCount then 'Un-resolve all' else 'Resolve all'
  methods:
    updateAll: ->
      resolveAll = !(this.resolved is this.commentsCount)
      CommentsStore.updateAll(resolveAll)

Vue.component 'resolve-all', ResolveAll
