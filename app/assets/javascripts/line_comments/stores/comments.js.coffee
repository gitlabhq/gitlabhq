@CommentsStore =
  state: {}
  create: (id, resolved) ->
    Vue.set(this.state, id, resolved)
  update: (id, resolved) ->
    this.state[id] = resolved
  updateAll: (state) ->
    for id,resolved of this.state
      this.update(id, state) if resolved isnt state
