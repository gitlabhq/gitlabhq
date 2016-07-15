@ResolveAll = Vue.extend
  props:
    discussionId: String
    namespace: String
  data: ->
    comments: CommentsStore.state
    loadingObject: CommentsStore.loading
  computed:
    allResolved: ->
      isResolved = true
      for noteId, resolved of this.comments[this.discussionId]
        isResolved = false unless resolved
      isResolved
    buttonText: ->
      if this.allResolved then "Un-resolve all" else "Resolve all"
    loading: ->
      this.loadingObject[this.discussionId]
  methods:
    resolve: ->
      ResolveService
        .resolveAll(this.namespace, this.discussionId, this.allResolved)
