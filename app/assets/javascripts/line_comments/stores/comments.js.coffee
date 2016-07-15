@CommentsStore =
  state: {}
  get: (discussionId, noteId) ->
    this.state[discussionId][noteId]
  create: (discussionId, noteId, resolved) ->
    unless this.state[discussionId]?
      Vue.set(this.state, discussionId, { loading: false })

    Vue.set(this.state[discussionId], noteId, resolved)
  update: (discussionId, noteId, resolved) ->
    this.state[discussionId][noteId] = resolved
  delete: (discussionId, noteId) ->
    Vue.delete(this.state[discussionId], noteId)

    if Object.keys(this.state[discussionId]).length is 0
      Vue.delete(this.state, discussionId)
