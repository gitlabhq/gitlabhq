@ResolveService =
  resolve: (endpoint, resolve) ->
    $.ajax
      data:
        resolved: resolve
      type: 'post'
      url: endpoint
  resolveAll: (endpoint, ids, resolve) ->
    $.ajax
      data:
        id: ids
        resolve: resolve
      type: 'post'
      url: endpoint
