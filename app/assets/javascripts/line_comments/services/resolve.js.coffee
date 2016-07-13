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

    Vue.http.headers.common['X-CSRF-Token'] = $.rails.csrfToken()
    @resource = Vue.resource('notes{/id}', {}, actions)

  resolve: (namespace, id, resolve) ->
    Vue.http.options.root = "/#{namespace}"
    @resource
      .resolve({ id: id }, { resolved: resolve })
      .then (response) ->
        if response.status is 200
          CommentsStore.update(id, resolve)

  resolveAll: (namespace, ids, resolve) ->
    Vue.http.options.root = "/#{namespace}"
    @resource
      .all({}, { ids: ids, resolve: resolve })
      .then (response) ->
        CommentsStore.updateAll(resolve)

$ ->
  @ResolveService = new ResolveService()
