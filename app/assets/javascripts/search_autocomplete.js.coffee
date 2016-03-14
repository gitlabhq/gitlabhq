class @SearchAutocomplete

  KEYCODE =
    ESCAPE: 27
    BACKSPACE: 8
    TAB: 9
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

    @locationBadgeEl = @$('.search-location-badge')
    @locationText = @$('.location-text')
    @scopeInputEl = @$('#scope')
    @searchInput = @$('.search-input')
    @projectInputEl = @$('#search_project_id')
    @groupInputEl = @$('#group_id')
    @searchCodeInputEl = @$('#search_code')
    @repositoryInputEl = @$('#repository_ref')
    @scopeInputEl = @$('#scope')

    @saveOriginalState()

    @searchInput.addClass('disabled')

    @bindEvents()

  $: (selector) ->
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

      # Location badge
      _location: $.trim(@locationText.text())
    }

  bindEvents: ->
    @searchInput.on 'keydown', @onSearchInputKeyDown
    @searchInput.on 'focus', @onSearchInputFocus
    @searchInput.on 'blur', @onSearchInputBlur

  enableAutocomplete: ->
    self = @
    @query = "?project_id=" + @projectId + "&project_ref=" + @projectRef
    dropdownMenu = self.dropdown.find('.dropdown-menu')

    @searchInput.glDropdown(
        filterInputBlur: false
        filterable: true
        filterRemote: true
        highlight: true
        filterInput: 'input#search'
        search:
          fields: ['text']
        data: (term, callback) ->
          $.ajax
            url: self.autocompletePath + self.query
            data:
              term: term
            beforeSend: ->
              # dropdownMenu.addClass 'is-loading'
            success: (response) ->
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
            complete: ->
              # dropdownMenu.removeClass 'is-loading'

          )

    @dropdown.addClass('open')
    @searchInput.removeClass('disabled')
    @autocomplete = true;

  onDropdownOpen: (e) =>
    @dropdown.dropdown('toggle')

  onSearchInputKeyDown: (e) =>
    # Remove tag when pressing backspace and input search is empty
    if e.keyCode is KEYCODE.BACKSPACE and e.currentTarget.value is ''
      @removeLocationBadge()
      @searchInput.focus()

    else if e.keyCode is KEYCODE.ESCAPE
      @searchInput.val('')
      @restoreOriginalState()
    else
      # Create new autocomplete if it hasn't been created yet and there's no badge
      if @autocomplete is undefined
        if !@badgePresent()
          @enableAutocomplete()
      else
        # There's a badge
        if @badgePresent()
          @disableAutocomplete()

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
              <a class='remove-badge' href='#'>x</a>
            </span>"
    @locationBadgeEl.html(html)

  restoreOriginalState: ->
    inputs = Object.keys @originalState

    for input in inputs
      @$("##{input}").val(@originalState[input])


    if @originalState._location is ''
      @locationBadgeEl.html('')
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
    # Remove scope
    @scopeInputEl.val('')

    # Remove group
    @groupInputEl.val('')

    # Remove project id
    @projectInputEl.val('')

    # Remove code search
    @searchCodeInputEl.val('')

    # Remove repository ref
    @repositoryInputEl.val('')

  removeLocationBadge: ->
    @locationBadgeEl.empty()

    # Reset state
    @resetSearchState()

  disableAutocomplete: ->
    if @autocomplete isnt undefined
      @searchInput.addClass('disabled')
    @autocomplete = undefined
