@ResolveAll = Vue.extend
  data: ->
    comments: CommentsStore.state
    loading: false
  props:
    namespace: String
  computed:
    resolved: ->
      resolvedCount = 0
      for noteId, resolved of this.comments
        resolvedCount++ if resolved
      resolvedCount
    commentsCount: ->
      Object.keys(this.comments).length
    buttonText: ->
      if this.allResolved then 'Un-resolve all' else 'Resolve all'
    allResolved: ->
      this.resolved is this.commentsCount
  methods:
    updateAll: ->
      ids = CommentsStore.getAllForState(this.allResolved)
      this.loading = true

      ResolveService
        .resolveAll(this.namespace, ids, !this.allResolved)
        .then =>
          this.loading = false
