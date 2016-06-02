class @Search
  constructor: ->
    $groupDropdown = $('.js-search-group-dropdown')
    $projectDropdown = $('.js-search-project-dropdown')
    @eventListeners()

    $groupDropdown.glDropdown(
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
      toggleLabel: (obj) ->
        "#{$groupDropdown.data('default-label')} #{obj.name}"
      clicked: =>
        @submitSearch()
    )

    $projectDropdown.glDropdown(
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
      toggleLabel: (obj) ->
        "#{$projectDropdown.data('default-label')} #{obj.name_with_namespace}"
      clicked: =>
        @submitSearch()
    )

  eventListeners: ->
    $(document)
      .off 'keyup', '.js-search-input'
      .on 'keyup', '.js-search-input', @searchKeyUp

    $(document)
      .off 'click', '.js-search-clear'
      .on 'click', '.js-search-clear', @clearSearchField

  submitSearch: ->
    $('.js-search-form').submit()

  searchKeyUp: ->
    $input = $(@)

    if $input.val() is ''
      $('.js-search-clear').addClass 'hidden'
    else
      $('.js-search-clear').removeClass 'hidden'

  clearSearchField: ->
    $('.js-search-input')
      .val ''
      .trigger 'keyup'
      .focus()
