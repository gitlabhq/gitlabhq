class ResolveService
  constructor: ->
    actions = {
      resolve:
        method: 'POST'
        url: 'notes{/id}/resolve'
      all:
        method: 'POST'
        url: 'notes/resolve_all'
    }

    @resource = Vue.resource('notes{/id}', {}, actions)

  setCSRF: ->
    Vue.http.headers.common['X-CSRF-Token'] = $.rails.csrfToken()

  resolve: (namespace, discussionId, noteId, resolve) ->
    @setCSRF()
    Vue.http.options.root = "/#{namespace}"

    @resource
      .resolve({ id: noteId }, { discussion: discussionId, resolved: resolve })
      .then (response) ->
        if response.status is 200
          CommentsStore.update(discussionId, noteId, resolve)

  resolveAll: (namespace, discussionId, allResolve) ->
    @setCSRF()
    Vue.http.options.root = "/#{namespace}"

    ids = []
    for noteId, resolved of CommentsStore.state[discussionId]
      ids.push(noteId) if resolved is allResolve

    CommentsStore.loading[discussionId] = true
    @resource
      .all({}, { ids: ids, discussion: discussionId, resolved: !allResolve })
      .then (response) ->
        if response.status is 200
          for noteId in ids
            CommentsStore.update(discussionId, noteId, !allResolve)

        CommentsStore.loading[discussionId] = false

@ResolveService = new ResolveService()
