class @SearchDropdowns
  constructor: ->
    $('.js-search-group-dropdown').glDropdown(
      selectable: true
      filterable: true
      fieldName: 'group_id'
      data: (term, callback) ->
        Api.groups term, null, (data) ->
          data.unshift(
            name: 'Any'
          )
          data.splice 1, 0, 'divider'

          callback(data)
      id: (obj) ->
        obj.id
      text: (obj) ->
        obj.name
      clicked: =>
        @submitSearch()
    )

    $('.js-search-project-dropdown').glDropdown(
      selectable: true
      filterable: true
      fieldName: 'project_id'
      data: (term, callback) ->
        Api.projects term, 'id', (data) ->
          data.unshift(
            name_with_namespace: 'Any'
          )
          data.splice 1, 0, 'divider'

          callback(data)
      id: (obj) ->
        obj.id
      text: (obj) ->
        obj.name_with_namespace
      clicked: =>
        @submitSearch()
    )

  submitSearch: ->
    $('.js-search-form').submit()
