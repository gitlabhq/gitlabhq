class @SearchAutocomplete
  constructor: (opts = {}) ->
    {
      @wrap = $('.search')
      @optsEl = @wrap.find('.search-autocomplete-opts')
      @autocompletePath = @optsEl.data('autocomplete-path')
      @projectId = @optsEl.data('autocomplete-project-id') || ''
      @projectRef = @optsEl.data('autocomplete-project-ref') || ''
    } = opts

    @keyCode =
      ESCAPE: 27
      BACKSPACE: 8
      TAB: 9
      ENTER: 13

    @locationBadgeEl = @$('.search-location-badge')
    @locationText = @$('.location-text')
    @searchInput = @$('.search-input')
    @projectInputEl = @$('#project_id')
    @groupInputEl = @$('#group_id')
    @searchCodeInputEl = @$('#search_code')
    @repositoryInputEl = @$('#repository_ref')
    @scopeInputEl = @$('#scope')

    @saveOriginalState()

    if @locationBadgeEl.is(':empty')
      @createAutocomplete()

    @bindEvents()

  $: (selector) ->
    @wrap.find(selector)

  saveOriginalState: ->
    @originalState = @serializeState()

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

  createAutocomplete: ->
    @query = "?project_id=" + @projectId + "&project_ref=" + @projectRef

    @catComplete = @searchInput.catcomplete
      appendTo: 'form.navbar-form'
      source: @autocompletePath + @query
      minLength: 1
      maxShowItems: 15
      position:
        # { my: "left top", at: "left bottom", collision: "none" }
        my: "left-10 top+9"
        at: "left bottom"
        collision: "none"
      close: (e) ->
        e.preventDefault()

      select: (event, ui) =>
        # Pressing enter choses an alternative
        if event.keyCode is @keyCode.ENTER
          @goToResult(ui.item)
        else
          # Pressing tab sets the scope
          if event.keyCode is @keyCode.TAB and ui.item.scope?
            @setLocationBadge(ui.item)
            @searchInput
              .val('') # remove selected value from input
              .focus()
          else
            # If option is not a scope go to page
            @goToResult(ui.item)

          # Return false to avoid focus on the next element
          return false


  bindEvents: ->
    @searchInput.on 'keydown', @onSearchInputKeyDown
    @searchInput.on 'focus', @onSearchInputFocus
    @searchInput.on 'blur', @onSearchInputBlur
    @wrap.on 'click', '.remove-badge', @onRemoveLocationBadgeClick

  onRemoveLocationBadgeClick: (e) =>
    e.preventDefault()
    @removeLocationBadge()
    @searchInput.focus()

  onSearchInputKeyDown: (e) =>
    # Remove tag when pressing backspace and input search is empty
    if e.keyCode is @keyCode.BACKSPACE and e.currentTarget.value is ''
      @removeLocationBadge()
      @destroyAutocomplete()
      @searchInput.focus()
    else if e.keyCode is @keyCode.ESCAPE
      @restoreOriginalState()
    else
      # Create new autocomplete if hasn't been created yet and there's no badge
      if !@catComplete? and @locationBadgeEl.is(':empty')
        @createAutocomplete()

  onSearchInputFocus: =>
    @wrap.addClass('search-active')

  onSearchInputBlur: =>
    @wrap.removeClass('search-active')

    # If input is blank then restore state
    @restoreOriginalState() if @searchInput.val() is ''

  addLocationBadge: (item) ->
    category = if item.category? then "#{item.category}: " else ''
    value = if item.value? then item.value else ''

    html = "<span class='location-badge'>
              <i class='location-text'>#{category}#{value}</i>
              <a class='remove-badge' href='#'>x</a>
            </span>"
    @locationBadgeEl.html(html)

  setLocationBadge: (item) ->
    @addLocationBadge(item)

    # Reset input states
    @resetSearchState()

    switch item.scope
      when 'projects'
        @projectInputEl.val(item.id)
        # @searchCodeInputEl.val('true') # TODO: always true for projects?
        # @repositoryInputEl.val('master') # TODO: always master?

      when 'groups'
        @groupInputEl.val(item.id)

  removeLocationBadge: ->
    @locationBadgeEl.empty()

    # Reset state
    @resetSearchState()

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

  goToResult: (result) ->
    location.href = result.url

  destroyAutocomplete: ->
    @catComplete.destroy() if @catComplete?
    @catComplete = null
