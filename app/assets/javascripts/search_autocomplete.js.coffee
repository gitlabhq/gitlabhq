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
    @dropdownContent = @dropdown.find('.dropdown-content')

    @locationBadgeEl = @getElement('.location-badge')
    @scopeInputEl = @getElement('#scope')
    @searchInput = @getElement('.search-input')
    @projectInputEl = @getElement('#search_project_id')
    @groupInputEl = @getElement('#group_id')
    @searchCodeInputEl = @getElement('#search_code')
    @repositoryInputEl = @getElement('#repository_ref')
    @clearInput = @getElement('.js-clear-input')

    @saveOriginalState()

    # Only when user is logged in
    @createAutocomplete() if gon.current_user_id

    @searchInput.addClass('disabled')

    @saveTextLength()

    @bindEvents()

  # Finds an element inside wrapper element
  getElement: (selector) ->
    @wrap.find(selector)

  saveOriginalState: ->
    @originalState = @serializeState()

  saveTextLength: ->
    @lastTextLength = @searchInput.val().length

  createAutocomplete: ->
    @searchInput.glDropdown
        filterInputBlur: false
        filterable: true
        filterRemote: true
        highlight: true
        enterCallback: false
        filterInput: 'input#search'
        search:
          fields: ['text']
        data: @getData.bind(@)
        selectable: true
        clicked: @onClick.bind(@)
        id: (data) -> _.escape(data.text)

  getData: (term, callback) ->
    _this = @

    unless term
      if contents = @getCategoryContents()
        @searchInput.data('glDropdown').filter.options.callback contents
        @enableAutocomplete()

      return

    # Prevent multiple ajax calls
    return if @loadingSuggestions

    @loadingSuggestions = true

    jqXHR = $.get(@autocompletePath, {
        project_id: @projectId
        project_ref: @projectRef
        term: term
      }, (response) ->
        # Hide dropdown menu if no suggestions returns
        if !response.length
          _this.disableAutocomplete()
          return

        data = []

        # List results
        firstCategory = true
        for suggestion in response

          # Add group header before list each group
          if lastCategory isnt suggestion.category
            data.push 'separator' if !firstCategory

            firstCategory = false if firstCategory

            data.push
              header: suggestion.category

            lastCategory = suggestion.category

          data.push
            id: "#{suggestion.category.toLowerCase()}-#{suggestion.id}"
            category: suggestion.category
            text: suggestion.label
            url: suggestion.url

        # Add option to proceed with the search
        if data.length
          data.push('separator')
          data.push
            text: "Result name contains \"#{term}\""
            url: "/search?\
                  search=#{term}\
                  &project_id=#{_this.projectInputEl.val()}\
                  &group_id=#{_this.groupInputEl.val()}"

        callback(data)
    ).always ->
      _this.loadingSuggestions = false


  getCategoryContents: ->

    userId = gon.current_user_id
    { utils, projectOptions, groupOptions, dashboardOptions } = gl

    if utils.isInGroupsPage() and groupOptions
      options = groupOptions[utils.getGroupSlug()]

    else if utils.isInProjectPage() and projectOptions
      options = projectOptions[utils.getProjectSlug()]

    else if dashboardOptions
      options = dashboardOptions

    { issuesPath, mrPath, name } = options

    items = [
      { header: "#{name}" }
      { text: 'Issues assigned to me', url: "#{issuesPath}/?assignee_id=#{userId}" }
      { text: "Issues I've created",   url: "#{issuesPath}/?author_id=#{userId}"   }
      'separator'
      { text: 'Merge requests assigned to me', url: "#{mrPath}/?assignee_id=#{userId}" }
      { text: "Merge requests I've created",   url: "#{mrPath}/?author_id=#{userId}"   }
    ]

    items.splice 0, 1 unless name

    return items


  serializeState: ->
    {
      # Search Criteria
      search_project_id: @projectInputEl.val()
      group_id: @groupInputEl.val()
      search_code: @searchCodeInputEl.val()
      repository_ref: @repositoryInputEl.val()
      scope: @scopeInputEl.val()

      # Location badge
      _location: @locationBadgeEl.text()
    }

  bindEvents: ->
    @searchInput.on 'keydown', @onSearchInputKeyDown
    @searchInput.on 'keyup', @onSearchInputKeyUp
    @searchInput.on 'click', @onSearchInputClick
    @searchInput.on 'focus', @onSearchInputFocus
    @searchInput.on 'blur', @onSearchInputBlur
    @clearInput.on 'click', @onClearInputClick
    @locationBadgeEl.on 'click', =>
      @searchInput.focus()

  enableAutocomplete: ->
    # No need to enable anything if user is not logged in
    return if !gon.current_user_id

    unless @dropdown.hasClass('open')
      _this = @
      @loadingSuggestions = false

      @dropdown
        .addClass('open')
        .trigger('shown.bs.dropdown')
      @searchInput.removeClass('disabled')

  onSearchInputKeyDown: =>
    # Saves last length of the entered text
    @saveTextLength()

  onSearchInputKeyUp: (e) =>
    switch e.keyCode
      when KEYCODE.BACKSPACE
        # when trying to remove the location badge
        if @lastTextLength is 0 and @badgePresent()
            @removeLocationBadge()

        # When removing the last character and no badge is present
        if @lastTextLength is 1
          @disableAutocomplete()

        # When removing any character from existin value
        if @lastTextLength > 1
          @enableAutocomplete()

      when KEYCODE.ESCAPE
        @restoreOriginalState()

      else
        # Handle the case when deleting the input value other than backspace
        # e.g. Pressing ctrl + backspace or ctrl + x
        if @searchInput.val() is ''
          @disableAutocomplete()
        else
          # We should display the menu only when input is not empty
          @enableAutocomplete() if e.keyCode isnt KEYCODE.ENTER

    @wrap.toggleClass 'has-value', !!e.target.value

    # Avoid falsy value to be returned
    return

  onSearchInputClick: (e) =>
    # Prevents closing the dropdown menu
    e.stopImmediatePropagation()

  onSearchInputFocus: =>
    @isFocused = true
    @wrap.addClass('search-active')

    @getData()  if @getValue() is ''


  getValue: -> return @searchInput.val()


  onClearInputClick: (e) =>
    e.preventDefault()
    @searchInput.val('').focus()

  onSearchInputBlur: (e) =>
    @isFocused = false
    @wrap.removeClass('search-active')

    # If input is blank then restore state
    if @searchInput.val() is ''
      @restoreOriginalState()

  addLocationBadge: (item) ->
    category = if item.category? then "#{item.category}: " else ''
    value = if item.value? then item.value else ''

    badgeText = "#{category}#{value}"
    @locationBadgeEl.text(badgeText).show()
    @wrap.addClass('has-location-badge')


  hasLocationBadge: -> return @wrap.is '.has-location-badge'


  restoreOriginalState: ->
    inputs = Object.keys @originalState

    for input in inputs
      @getElement("##{input}").val(@originalState[input])

    if @originalState._location is ''
      @locationBadgeEl.hide()
    else
      @addLocationBadge(
        value: @originalState._location
      )

  badgePresent: ->
    @locationBadgeEl.length

  resetSearchState: ->
    inputs = Object.keys @originalState

    for input in inputs

      # _location isnt a input
      break if input is '_location'

      @getElement("##{input}").val('')


  removeLocationBadge: ->

    @locationBadgeEl.hide()
    @resetSearchState()
    @wrap.removeClass('has-location-badge')
    @disableAutocomplete()


  disableAutocomplete: ->
    @searchInput.addClass('disabled')
    @dropdown.removeClass('open')
    @restoreMenu()

  restoreMenu: ->
    html = "<ul>
              <li><a class='dropdown-menu-empty-link is-focused'>Loading...</a></li>
            </ul>"
    @dropdownContent.html(html)

  onClick: (item, $el, e) ->
    if location.pathname.indexOf(item.url) isnt -1
      e.preventDefault()
      if not @badgePresent
        if item.category is 'Projects'
          @projectInputEl.val(item.id)
          @addLocationBadge(
            value: 'This project'
          )

        if item.category is 'Groups'
          @groupInputEl.val(item.id)
          @addLocationBadge(
            value: 'This group'
          )

      $el.removeClass('is-active')
      @disableAutocomplete()
      @searchInput.val('').focus()
