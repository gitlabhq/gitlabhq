class @SearchAutocomplete

  KEYCODE =
    ESCAPE: 27
    BACKSPACE: 8
    ENTER: 13

  constructor: (opts = {}) ->
    {
      @wrap = $('.search')

      @optsEl = @wrap.find('.search-autocomplete-opts')
      @autocompletePath = @optsEl.data('autocomplete-path')
      @projectId = @optsEl.data('autocomplete-project-id') || ''
      @projectRef = @optsEl.data('autocomplete-project-ref') || ''

    } = opts

    # Dropdown Element
    @dropdown = @wrap.find('.dropdown')

    @locationBadgeEl = @getElement('.search-location-badge')
    @locationText = @getElement('.location-text')
    @scopeInputEl = @getElement('#scope')
    @searchInput = @getElement('.search-input')
    @projectInputEl = @getElement('#search_project_id')
    @groupInputEl = @getElement('#group_id')
    @searchCodeInputEl = @getElement('#search_code')
    @repositoryInputEl = @getElement('#repository_ref')

    @saveOriginalState()

    @searchInput.addClass('disabled')
    @autocomplete = false

    @bindEvents()

  # Finds an element inside wrapper element
  getElement: (selector) ->
    @wrap.find(selector)

  saveOriginalState: ->
    @originalState = @serializeState()

  serializeState: ->
    {
      # Search Criteria
      project_id: @projectInputEl.val()
      group_id: @groupInputEl.val()
      search_code: @searchCodeInputEl.val()
      repository_ref: @repositoryInputEl.val()
      scope: @scopeInputEl.val()

      # Location badge
      _location: $.trim(@locationText.text())
    }

  bindEvents: ->
    @searchInput.on 'keydown', @onSearchInputKeyDown
    @searchInput.on 'focus', @onSearchInputFocus
    @searchInput.on 'blur', @onSearchInputBlur

  enableAutocomplete: ->
    return if @autocomplete

    dropdownMenu = @dropdown.find('.dropdown-menu')
    _this = @
    loading = false

    @searchInput.glDropdown
        filterInputBlur: false
        filterable: true
        filterRemote: true
        highlight: true
        filterInput: 'input#search'
        search:
          fields: ['text']
        data: (term, callback) ->
          # Ensure this is not called when autocomplete is disabled because
          # this method still will be called because `GitLabDropdownFilter` is triggering this on keyup
          return if _this.autocomplete is false

          # Do not trigger request if input is empty
          return if _this.searchInput.val() is ''

          # Prevent multiple ajax calls
          return if loading

          loading = true

          jqXHR = $.get(_this.autocompletePath, {
              project_id: _this.projectId
              project_ref: _this.projectRef
              term: term
            }, (response) ->
              data = []

              # Save groups ordering according to server response
              groupNames =  _.unique(_.pluck(response, 'category'))

              # Group results by category name
              groups = _.groupBy response, (item) ->
                item.category

              # List results
              for groupName in groupNames

                # Add group header before list each group
                data.push
                  header: groupName

                # List group
                for item in groups[groupName]
                  data.push
                    text: item.label
                    url: item.url
              callback(data)
          ).always ->
            loading = false

    @dropdown.addClass('open')
    @searchInput.removeClass('disabled')
    @autocomplete = true

  onDropdownOpen: (e) =>
    @dropdown.dropdown('toggle')

  onSearchInputKeyDown: (e) =>
    switch e.keyCode
      when KEYCODE.BACKSPACE
        if e.currentTarget.value is ''
          @removeLocationBadge()
          @searchInput.focus()
      when KEYCODE.ESCAPE
        if @badgePresent()
        else
          @restoreOriginalState()

          # If after restoring there's a badge
          @disableAutocomplete() if @badgePresent()
      else
        if @badgePresent()
          @disableAutocomplete()
        else
          @enableAutocomplete()

    # Avoid falsy value to be returned
    return

  onSearchInputFocus: =>
    @wrap.addClass('search-active')

  onSearchInputBlur: =>
    @wrap.removeClass('search-active')

    # If input is blank then restore state
    if @searchInput.val() is ''
      @restoreOriginalState()

  addLocationBadge: (item) ->
    category = if item.category? then "#{item.category}: " else ''
    value = if item.value? then item.value else ''

    html = "<span class='location-badge'>
              <i class='location-text'>#{category}#{value}</i>
            </span>"
    @locationBadgeEl.html(html)

  restoreOriginalState: ->
    inputs = Object.keys @originalState

    for input in inputs
      @getElement("##{input}").val(@originalState[input])


    if @originalState._location is ''
      @locationBadgeEl.empty()
    else
      @addLocationBadge(
        value: @originalState._location
      )

    @dropdown.removeClass 'open'

    # Only add class if there's a badge
    if @badgePresent()
      @searchInput.addClass 'disabled'

  badgePresent: ->
    @locationBadgeEl.children().length

  resetSearchState: ->
    inputs = Object.keys @originalState

    for input in inputs

      # _location isnt a input
      break if input is '_location'

      # renamed to avoid tests to fail
      if input is 'project_id' then input = 'search_project_id'

      @getElement("##{input}").val('')

  removeLocationBadge: ->
    @locationBadgeEl.empty()

    # Reset state
    @resetSearchState()

  disableAutocomplete: ->
    if @autocomplete
      @searchInput.addClass('disabled')
    @autocomplete = false
