@ResolveAll = Vue.extend
  props:
    discussionId: String
    namespace: String
  data: ->
    comments: CommentsStore.state
  computed:
    allResolved: ->
      isResolved = true
      for noteId, resolved of this.comments[this.discussionId]
        unless noteId is "loading"
          isResolved = false unless resolved
      isResolved
    buttonText: ->
      if this.allResolved then "Un-resolve all" else "Resolve all"
    loading: -> this.comments[this.discussionId].loading
  methods:
    resolve: ->
      ResolveService
        .resolveAll(this.namespace, this.discussionId, this.allResolved)
