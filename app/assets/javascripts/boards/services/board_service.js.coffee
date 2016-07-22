class @BoardService
  constructor: (@root) ->
    Vue.http.options.root = @root

    @resource = Vue.resource "#{@root}{/id}", {},
      all:
        method: 'GET'
        url: 'all'

  setCSRF: ->
  	Vue.http.headers.common['X-CSRF-Token'] = $.rails.csrfToken()

  all: ->
    @setCSRF()
    @resource.all()

  updateBoard: (id, index) ->
    @setCSRF()
    @resource.update { id: id }, { index: index }
