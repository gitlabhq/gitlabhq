@ResolveCount = Vue.extend
  data: ->
    comments: CommentsStore.state
    loading: false
  computed:
    resolved: ->
      resolvedCount = 0
      for discussionId, comments of this.comments
        resolved = true
        for noteId, resolved of comments
          resolved = false unless resolved
        resolvedCount++ if resolved
      resolvedCount
    commentsCount: ->
      Object.keys(this.comments).length
    allResolved: ->
      this.resolved is this.commentsCount
