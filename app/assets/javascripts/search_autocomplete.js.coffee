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
    @clearInput = @getElement('.js-clear-input')

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
    @clearInput.on 'click', @onRemoveLocationClick

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

              # List results
              for suggestion in response

                # Add group header before list each group
                if lastCategory isnt suggestion.category
                  data.push
                    header: suggestion.category

                  lastCategory = suggestion.category

                data.push
                  text: suggestion.label
                  url: suggestion.url

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

  onRemoveLocationClick: (e) =>
    e.preventDefault()
    @removeLocationBadge()
    @searchInput.val('').focus()
    @skipBlurEvent = true

  onSearchInputBlur: (e) =>
    @skipBlurEvent = false

    # We should wait to make sure we are not clearing the input instead
    setTimeout( =>
      return if @skipBlurEvent

      @wrap.removeClass('search-active')

      # If input is blank then restore state
      if @searchInput.val() is ''
        @restoreOriginalState()
    , 100)

  addLocationBadge: (item) ->
    category = if item.category? then "#{item.category}: " else ''
    value = if item.value? then item.value else ''

    html = "<span class='location-badge'>
              <i class='location-text'>#{category}#{value}</i>
            </span>"
    @locationBadgeEl.html(html)
    @wrap.addClass('has-location-badge')

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

    @wrap.removeClass('has-location-badge')

  disableAutocomplete: ->
    if @autocomplete
      @searchInput.addClass('disabled')
    @autocomplete = false
