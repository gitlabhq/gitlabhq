@CommentsStore =
  state: {}
  create: (id, resolved) ->
    Vue.set(this.state, id, resolved)
  update: (id, resolved) ->
    this.state[id] = resolved
  delete: (id) ->
    Vue.delete(this.state, id)
  updateAll: (state) ->
    for id,resolved of this.state
      this.update(id, state) if resolved isnt state
