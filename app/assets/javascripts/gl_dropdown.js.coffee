class GitLabDropdownFilter
  BLUR_KEYCODES = [27, 40]
  ARROW_KEY_CODES = [38, 40]
  HAS_VALUE_CLASS = 'has-value'

  constructor: (@input, @options) ->
    {
      @filterInputBlur = true
    } = @options

    $inputContainer = @input.parent()
    $clearButton = $inputContainer.find '.js-dropdown-input-clear'

    @indeterminateIds = []

    # Clear click
    $clearButton.on 'click', (e) =>
      e.preventDefault()
      e.stopPropagation()
      @input
        .val ''
        .trigger 'keyup'
        .focus()

    # Key events
    timeout = ''
    @input.on 'keyup', (e) =>
      keyCode = e.which

      return if ARROW_KEY_CODES.indexOf(keyCode) >= 0

      if @input.val() isnt '' and not $inputContainer.hasClass HAS_VALUE_CLASS
        $inputContainer.addClass HAS_VALUE_CLASS
      else if @input.val() is '' and $inputContainer.hasClass HAS_VALUE_CLASS
        $inputContainer.removeClass HAS_VALUE_CLASS

      return false if keyCode is 13

      # Only filter asynchronously only if option remote is set
      if @options.remote
        clearTimeout timeout
        timeout = setTimeout =>
          blur_field = @shouldBlur keyCode

          if blur_field and @filterInputBlur
            @input.blur()

          @options.query @input.val(), (data) =>
            @options.callback data
        , 250
      else
        @filter @input.val()

  shouldBlur: (keyCode) ->
    BLUR_KEYCODES.indexOf(keyCode) >= 0

  filter: (search_text) ->
    @options.onFilter(search_text) if @options.onFilter
    data = @options.data()

    if data? and not @options.filterByText
      results = data

      if search_text isnt ''
        # When data is an array of objects therefore [object Array] e.g.
        # [
        #   { prop: 'foo' },
        #   { prop: 'baz' }
        # ]
        if _.isArray(data)
          results = fuzzaldrinPlus.filter data, search_text,
            key: @options.keys
        else
          # If data is grouped therefore an [object Object]. e.g.
          # {
          #   groupName1: [
          #     { prop: 'foo' },
          #     { prop: 'baz' }
          #   ],
          #   groupName2: [
          #     { prop: 'abc' },
          #     { prop: 'def' }
          #   ]
          # }
          if gl.utils.isObject data
            results = {}
            for key, group of data
              tmp = fuzzaldrinPlus.filter group, search_text,
                key: @options.keys

              if tmp.length
                results[key] = tmp.map (item) -> item

      @options.callback results
    else
      elements = @options.elements()

      if search_text
        elements.each ->
          $el = $(this)
          matches = fuzzaldrinPlus.match $el.text().trim(), search_text

          unless $el.is '.dropdown-header'
            if matches.length
              $el.show()
            else
              $el.hide()
      else
        elements.show()

class GitLabDropdownRemote
  constructor: (@dataEndpoint, @options) ->

  execute: ->
    if typeof @dataEndpoint is 'string'
      @fetchData()
    else if typeof @dataEndpoint is 'function'
      @options.beforeSend() if @options.beforeSend

      # Fetch the data by calling the data funcfion
      @dataEndpoint '', (data) =>
        @options.success(data) if @options.success
        @options.beforeSend() if @options.beforeSend

  # Fetch the data through ajax if the data is a string
  fetchData: ->
    $.ajax
      url: @dataEndpoint,
      dataType: @options.dataType,
      beforeSend: =>
        @options.beforeSend() if @options.beforeSend
      success: (data) =>
        @options.success(data) if @options.success

class GitLabDropdown
  LOADING_CLASS = 'is-loading'
  PAGE_TWO_CLASS = 'is-page-two'
  ACTIVE_CLASS = 'is-active'
  INDETERMINATE_CLASS = 'is-indeterminate'
  NON_SELECTABLE_CLASSES = '.divider, .separator, .dropdown-header, .dropdown-menu-empty-link'
  SELECTABLE_CLASSES = ".dropdown-content li:not(#{NON_SELECTABLE_CLASSES})"
  FILTER_INPUT = '.dropdown-input .dropdown-input-field'
  currentIndex = -1
  CURSOR_SELECT_SCROLL_PADDING = 5

  constructor: (@el, @options) ->
    self = this
    selector = $(@el).data 'target'
    @dropdown = if selector? then $(selector) else $(@el).parent()

    # Set Defaults
    {
      # If no input is passed create a default one
      @filterInput = @getElement FILTER_INPUT
      @highlight = false
      @filterInputBlur = true
    } = @options

    self = this

    # If selector was passed
    @filterInput = @getElement(@filterInput) if _.isString @filterInput

    searchFields = if @options.search then @options.search.fields else []

    if @options.data
      # If we provided data
      # data could be an array of objects or a group of arrays
      if _.isObject(@options.data) and not _.isFunction @options.data
        @fullData = @options.data
        @parseData @options.data
      else
        # Remote data
        @remote = new GitLabDropdownRemote @options.data,
          dataType: @options.dataType,
          beforeSend: @toggleLoading.bind this
          success: (data) =>
            @fullData = data

            # Reset selected row index on new data
            currentIndex = -1
            @parseData @fullData

            if @options.filterable and @filter and @filter.input
              @filter.input.trigger 'keyup'

    # Init filterable
    if @options.filterable
      @filter = new GitLabDropdownFilter @filterInput,
        filterInputBlur: @filterInputBlur
        filterByText: @options.filterByText
        onFilter: @options.onFilter
        remote: @options.filterRemote
        query: @options.data
        keys: searchFields
        elements: =>
          selector = SELECTABLE_CLASSES

          if @dropdown.find('.dropdown-toggle-page').length
            selector = ".dropdown-page-one #{selector}"

          $(selector)
        data: =>
          @fullData
        callback: (data) =>
          @parseData data

          unless @filterInput.val() is ''
            selector = '.dropdown-content li:not(.divider):visible'

            if @dropdown.find('.dropdown-toggle-page').length
              selector = ".dropdown-page-one #{selector}"

            $(selector, @dropdown)
              .first()
              .find('a')
              .addClass('is-focused')

            currentIndex = 0


    # Event listeners

    @dropdown.on 'shown.bs.dropdown', @opened
    @dropdown.on 'hidden.bs.dropdown', @hidden
    $(@el).on 'update.label', @updateLabel
    @dropdown.on 'click', '.dropdown-menu, .dropdown-menu-close', @shouldPropagate
    @dropdown.on 'keyup', (e) =>
      $('.dropdown-menu-close', @dropdown).trigger 'click' if e.which is 27

    @dropdown.on 'blur', 'a', (e) =>
      if e.relatedTarget?
        $relatedTarget = $(e.relatedTarget)
        $dropdownMenu = $relatedTarget.closest('.dropdown-menu')

        @dropdown.removeClass('open') if $dropdownMenu.length is 0

    if @dropdown.find('.dropdown-toggle-page').length
      @dropdown.find('.dropdown-toggle-page, .dropdown-menu-back').on 'click', (e) =>
        e.preventDefault()
        e.stopPropagation()

        @togglePage()

    if @options.selectable
      selector = '.dropdown-content a'

      if @dropdown.find('.dropdown-toggle-page').length
        selector = '.dropdown-page-one .dropdown-content a'

      @dropdown.on 'click', selector, (e) ->
        $el = $(this)
        selected = self.rowClicked $el

        if self.options.clicked
          self.options.clicked(selected, $el, e)

        $el.trigger('blur')

  # Finds an element inside wrapper element
  getElement: (selector) ->
    @dropdown.find selector

  toggleLoading: ->
    $('.dropdown-menu', @dropdown).toggleClass LOADING_CLASS

  togglePage: ->
    menu = $('.dropdown-menu', @dropdown)

    if menu.hasClass(PAGE_TWO_CLASS)
      @remote.execute() if @remote

    menu.toggleClass PAGE_TWO_CLASS

    # Focus first visible input on active page
    @dropdown.find('[class^="dropdown-page-"]:visible :text:visible:first').focus()

  parseData: (data) ->
    @renderedData = data

    if @options.filterable and data.length is 0
      # render no matching results
      html = [@noResults()]
    else
      # Handle array groups
      if gl.utils.isObject data
        html = []
        for name, groupData of data
          # Add header for each group
          html.push(@renderItem(header: name, name))

          @renderData(groupData, name)
            .map (item) ->
              html.push item
      else
        # Render each row
        html = @renderData(data)

    # Render the full menu
    full_html = @renderMenu(html)

    @appendMenu(full_html)

  renderData: (data, group = false) ->
    data.map (obj, index) =>
      @renderItem(obj, group, index)

  shouldPropagate: (e) =>
    $target = $(e.target) if @options.multiSelect
    unless $target.hasClass('dropdown-menu-close') and $target.hasClass('dropdown-menu-close-icon') and $target.data('is-link')
      e.stopPropagation()
      false
    else
      true

  opened: =>
    @resetRows()
    @addArrowKeyEvent()

    @options.setIndeterminateIds.call this if @options.setIndeterminateIds

    @options.setActiveIds.call this if @options.setActiveIds

    # Makes indeterminate items effective
    if @fullData and @dropdown.find('.dropdown-menu-toggle').hasClass('js-filter-bulk-update')
      @parseData @fullData

    contentHtml = $('.dropdown-content', @dropdown).html()
    @remote.execute() if @remote and contentHtml is ''

    @filterInput.focus() if @options.filterable

    @dropdown.trigger('shown.gl.dropdown')

  hidden: (e) =>
    @resetRows()
    @removeArrayKeyEvent()

    $input = @dropdown.find('.dropdown-input-field')

    if @options.filterable
      $input
        .blur()
        .val('')

    # Triggering 'keyup' will re-render the dropdown which is not always required
    # specially if we want to keep the state of the dropdown needed for bulk-assignment
    $input.trigger('keyup') unless @options.persistWhenHide

    if @dropdown.find('.dropdown-toggle-page').length
      $('.dropdown-menu', @dropdown).removeClass PAGE_TWO_CLASS

    @options.hidden.call this, e if @options.hidden

    @dropdown.trigger('hidden.gl.dropdown')


  # Render the full menu
  renderMenu: (html) ->
    menu_html = ''

    if @options.renderMenu
      menu_html = @options.renderMenu html
    else
      menu_html = $('<ul/>').append html

    menu_html

  # Append the menu into the dropdown
  appendMenu: (html) ->
    selector = '.dropdown-content'
    if @dropdown.find('.dropdown-toggle-page').length
      selector = '.dropdown-page-one .dropdown-content'
    $(selector, @dropdown)
      .empty()
      .append html

  # Render the row
  renderItem: (data, group = false, index = false) ->
    html = ''

    # Divider
    return '<li class='divider'></li>' if data is 'divider'

    # Separator is a full-width divider
    return '<li class='separator'></li>' if data is 'separator'

    # Header
    return _.template('<li class="dropdown-header"><%- header %></li>')({ header: data.header }) if data.header?

    if @options.renderRow
      # Call the render function
      html = @options.renderRow.call(@options, data, @)
    else
      unless selected
        value = if @options.id then @options.id(data) else data.id
        fieldName = @options.fieldName
        field = @dropdown.parent().find("input[name='#{fieldName}'][value='#{value}']")
        selected = true if field.length

      # Set URL
      if @options.url?
        url = @options.url(data)
      else
        url = if data.url? then data.url else '#'

      # Set Text
      if @options.text?
        text = @options.text(data)
      else
        text = if data.text? then data.text else ''

      cssClass = ''

      cssClass = 'is-active' if selected

      if @highlight
        text = @highlightTextMatches(text, @filterInput.val())

      if group
        groupAttrs = "data-group=#{group} data-index=#{index}"
      else
        groupAttrs = ''
      html = _.template('<li>
        <a href="<%- url %>" <%- groupAttrs %> class="<%- cssClass %>">
          <%= text %>
        </a>
      </li>')({
        url: url
        groupAttrs: groupAttrs
        cssClass: cssClass
        text: text
      })

    html

  highlightTextMatches: (text, term) ->
    occurrences = fuzzaldrinPlus.match(text, term)
    text.split('').map((character, i) ->
      if i in occurrences then "<b>#{character}</b>" else character
    ).join('')

  noResults: ->
    html = '<li class="dropdown-menu-empty-link">
      <a href="#" class="is-focused">
        No matching results.
      </a>
    </li>'

  rowClicked: (el) ->
    fieldName = @options.fieldName
    isInput = $(@el).is('input')

    if @renderedData
      groupName = el.data 'group'
      if groupName
        selectedIndex = el.data 'index'
        selectedObject = @renderedData[groupName][selectedIndex]
      else
        selectedIndex = el.closest('li').index()
        selectedObject = @renderedData[selectedIndex]

    value = if @options.id then @options.id(selectedObject, el) else selectedObject.id

    if isInput
      field = $(@el)
    else
      field = @dropdown.parent().find("input[name='#{fieldName}'][value='#{value}']")

    if el.hasClass(ACTIVE_CLASS)
      el.removeClass(ACTIVE_CLASS)

      if isInput
        field.val('')
      else
        field.remove()

      # Toggle the dropdown label
      if @options.toggleLabel
        @updateLabel(selectedObject, el, this)
      else
        selectedObject
    else if el.hasClass(INDETERMINATE_CLASS)
      el.addClass ACTIVE_CLASS
      el.removeClass INDETERMINATE_CLASS

      field.remove() unless value?

      if not field.length and fieldName
        @addInput(fieldName, value)

      selectedObject
    else
      if not @options.multiSelect or el.hasClass('dropdown-clear-active')
        @dropdown.find(".#{ACTIVE_CLASS}").removeClass ACTIVE_CLASS

        unless isInput
          @dropdown.parent().find("input[name='#{fieldName}']").remove()

      field.remove() unless value?

      # Toggle active class for the tick mark
      el.addClass ACTIVE_CLASS

      # Toggle the dropdown label
      if @options.toggleLabel
        @updateLabel(selectedObject, el, this)
      if value?
        if not field.length and fieldName
          @addInput(fieldName, value)
        else
          field
            .val value
            .trigger 'change'

      selectedObject

  addInput: (fieldName, value)->
    # Create hidden input for form
    $input = $('<input>').attr('type', 'hidden')
                         .attr('name', fieldName)
                        .val(value)

    if @options.inputId?
      $input.attr('id', @options.inputId)

    @dropdown.before $input

  selectRowAtIndex: (e, index) ->
    # Dropdown list item link selector, excluding non-selectable list items
    selector = "#{SELECTABLE_CLASSES}:eq(#{index}) a"

    if @dropdown.find('.dropdown-toggle-page').length
      selector = ".dropdown-page-one #{selector}"

    # simulate a click on the first link
    $el = $(selector, @dropdown)
    if $el.length
      e.preventDefault()
      e.stopImmediatePropagation()
      $el.first().trigger 'click'
      href = $el.attr 'href'
      Turbolinks.visit(href) if href and href isnt '#'

  addArrowKeyEvent: ->
    ARROW_KEY_CODES = [38, 40]
    $input = @dropdown.find '.dropdown-input-field'

    # Dropdown list item selector, excluding non-selectable list items
    selector = SELECTABLE_CLASSES
    if @dropdown.find('.dropdown-toggle-page').length
      selector = ".dropdown-page-one #{selector}"

    $('body').on 'keydown', (e) =>
      currentKeyCode = e.which

      if ARROW_KEY_CODES.indexOf(currentKeyCode) >= 0
        e.preventDefault()
        e.stopImmediatePropagation()

        PREV_INDEX = currentIndex
        $listItems = $(selector, @dropdown)

        # if @options.filterable
        #   $input.blur()

        if currentKeyCode is 40
          # Move down
          currentIndex += 1 if currentIndex < ($listItems.length - 1)
        else if currentKeyCode is 38
          # Move up
          currentIndex -= 1 if currentIndex > 0

        if currentIndex isnt PREV_INDEX
          @highlightRowAtIndex($listItems, currentIndex)

        return false

      # If enter is pressed and a row is highlighted, select it
      if currentKeyCode is 13 and currentIndex isnt -1
        e.preventDefault()
        e.stopImmediatePropagation()
        @selectRowAtIndex e, currentIndex

  removeArrayKeyEvent: ->
    $('body').off 'keydown'

  # Resets the currently selected item row index and removes all highlights
  resetRows: ->
    currentIndex = -1
    $('.is-focused', @dropdown).removeClass 'is-focused'

  highlightRowAtIndex: ($listItems, index) ->
    # Remove the class for the previously focused row
    $('.is-focused', @dropdown).removeClass 'is-focused'

    # Update the class for the row at the specific index
    $listItem = $listItems.eq(index)
    $listItem.find('a:first-child').addClass 'is-focused'

    # Dropdown content scroll area
    $dropdownContent = $listItem.closest('.dropdown-content')
    dropdownScrollTop = $dropdownContent.scrollTop()
    dropdownContentHeight = $dropdownContent.outerHeight()
    dropdownContentTop = $dropdownContent.prop('offsetTop')
    dropdownContentBottom = dropdownContentTop + dropdownContentHeight

    # Get the offset bottom of the list item
    listItemHeight = $listItem.outerHeight()
    listItemTop = $listItem.prop('offsetTop')
    listItemBottom = listItemTop + listItemHeight

    if index is 0
      # If this is the first item in the list, scroll to the top
      $dropdownContent.scrollTop(0)
    else if index is $listItems.length - 1
      # If this is the last item in the list, scroll to the bottom
      $dropdownContent.scrollTop $dropdownContent.prop 'scrollHeight'
    else if listItemBottom > dropdownContentBottom + dropdownScrollTop
      # Scroll the dropdown content down with a little padding
      $dropdownContent.scrollTop(listItemBottom - dropdownContentBottom + CURSOR_SELECT_SCROLL_PADDING)
    else if listItemTop < dropdownContentTop + dropdownScrollTop
      # Scroll the dropdown content up with a little padding
      $dropdownContent.scrollTop(listItemTop - dropdownContentTop - CURSOR_SELECT_SCROLL_PADDING)

  updateLabel: (selected = null, el = null, instance = null) =>
    $(@el).find('.dropdown-toggle-text').text @options.toggleLabel(selected, el, instance)

$.fn.glDropdown = (opts) ->
  @each ->
    unless $.data this, 'glDropdown'
      $.data this, 'glDropdown', new GitLabDropdown this, opts
