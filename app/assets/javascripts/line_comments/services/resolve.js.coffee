@ResolveService =
  resolve: (endpoint, resolve) ->
    $.ajax
      data:
        resolved: resolve
      type: 'post'
      url: endpoint
  resolveAll: (ids) ->
    $.ajax
      data:
        id: ids
      type: 'get'
      url: '/'
  unResolveAll: (ids) ->
    $.ajax
      data:
        id: ids
      type: 'get'
      url: '/'
