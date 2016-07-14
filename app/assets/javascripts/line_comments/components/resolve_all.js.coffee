@ResolveAll = Vue.extend
  props:
    discussionId: String
    namespace: String
  data: ->
    comments: CommentsStore.state
    loading: false
  computed:
    allResolved: ->
      isResolved = true
      for noteId, resolved of this.comments[this.discussionId]
        isResolved = false unless resolved
      isResolved
    buttonText: ->
      if this.allResolved then "Un-resolve all" else "Resolve all"
  methods:
    resolve: ->
      this.loading = true
      ResolveService
        .resolveAll(this.namespace, this.discussionId, this.allResolved)
        .then =>
          this.loading = false
