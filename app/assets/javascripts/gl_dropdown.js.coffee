class GitLabDropdownFilter
  BLUR_KEYCODES = [27, 40]
  ARROW_KEY_CODES = [38, 40]
  HAS_VALUE_CLASS = "has-value"

  constructor: (@input, @options) ->
    {
      @filterInputBlur = true
    } = @options

    $inputContainer = @input.parent()
    $clearButton = $inputContainer.find('.js-dropdown-input-clear')

    # Clear click
    $clearButton.on 'click', (e) =>
      e.preventDefault()
      e.stopPropagation()
      @input
        .val('')
        .trigger('keyup')
        .focus()

    # Key events
    timeout = ""
    @input.on "keyup", (e) =>
      keyCode = e.which

      return if ARROW_KEY_CODES.indexOf(keyCode) >= 0

      if @input.val() isnt "" and !$inputContainer.hasClass HAS_VALUE_CLASS
        $inputContainer.addClass HAS_VALUE_CLASS
      else if @input.val() is "" and $inputContainer.hasClass HAS_VALUE_CLASS
        $inputContainer.removeClass HAS_VALUE_CLASS

      if keyCode is 13 and @input.val() isnt ""
        if @options.enterCallback
          @options.enterCallback()
        return

      clearTimeout timeout
      timeout = setTimeout =>
        blur_field = @shouldBlur keyCode
        search_text = @input.val()

        if blur_field and @filterInputBlur
          @input.blur()

        if @options.remote
          @options.query search_text, (data) =>
            @options.callback(data)
        else
          @filter search_text
      , 250

  shouldBlur: (keyCode) ->
    return BLUR_KEYCODES.indexOf(keyCode) >= 0

  filter: (search_text) ->
    data = @options.data()
    results = data

    if search_text isnt ""
      results = fuzzaldrinPlus.filter(data, search_text,
        key: @options.keys
      )

    @options.callback results

class GitLabDropdownRemote
  constructor: (@dataEndpoint, @options) ->

  execute: ->
    if typeof @dataEndpoint is "string"
      @fetchData()
    else if typeof @dataEndpoint is "function"
      if @options.beforeSend
        @options.beforeSend()

      # Fetch the data by calling the data funcfion
      @dataEndpoint "", (data) =>
        if @options.success
          @options.success(data)

        if @options.beforeSend
          @options.beforeSend()

  # Fetch the data through ajax if the data is a string
  fetchData: ->
    $.ajax(
      url: @dataEndpoint,
      dataType: @options.dataType,
      beforeSend: =>
        if @options.beforeSend
          @options.beforeSend()
      success: (data) =>
        if @options.success
          @options.success(data)
    )

class GitLabDropdown
  LOADING_CLASS = "is-loading"
  PAGE_TWO_CLASS = "is-page-two"
  ACTIVE_CLASS = "is-active"
  currentIndex = -1

  FILTER_INPUT = '.dropdown-input .dropdown-input-field'

  constructor: (@el, @options) ->
    @dropdown = $(@el).parent()

    # Set Defaults
    {
      # If no input is passed create a default one
      @filterInput = @getElement(FILTER_INPUT)
      @highlight = false
      @filterInputBlur = true
      @enterCallback = true
    } = @options

    self = @

    # If selector was passed
    if _.isString(@filterInput)
      @filterInput = @getElement(@filterInput)

    search_fields = if @options.search then @options.search.fields else [];

    if @options.data
      # If data is an array
      if _.isArray @options.data
        @fullData = @options.data
        @parseData @options.data
      else
        # Remote data
        @remote = new GitLabDropdownRemote @options.data, {
          dataType: @options.dataType,
          beforeSend: @toggleLoading.bind(@)
          success: (data) =>
            @fullData = data

            @parseData @fullData
        }

    # Init filterable
    if @options.filterable
      @filter = new GitLabDropdownFilter @filterInput,
        filterInputBlur: @filterInputBlur
        remote: @options.filterRemote
        query: @options.data
        keys: @options.search.fields
        data: =>
          return @fullData
        callback: (data) =>
          currentIndex = -1
          @parseData data
        enterCallback: =>
          if @enterCallback
            @selectRowAtIndex 0

    # Event listeners

    @dropdown.on "shown.bs.dropdown", @opened
    @dropdown.on "hidden.bs.dropdown", @hidden
    @dropdown.on "click", ".dropdown-menu, .dropdown-menu-close", @shouldPropagate

    if @dropdown.find(".dropdown-toggle-page").length
      @dropdown.find(".dropdown-toggle-page, .dropdown-menu-back").on "click", (e) =>
        e.preventDefault()
        e.stopPropagation()

        @togglePage()

    if @options.selectable
      selector = ".dropdown-content a"

      if @dropdown.find(".dropdown-toggle-page").length
        selector = ".dropdown-page-one .dropdown-content a"

      @dropdown.on "click", selector, (e) ->
        $el = $(@)
        selected = self.rowClicked $el

        if self.options.clicked
          self.options.clicked(selected, $el, e)

  # Finds an element inside wrapper element
  getElement: (selector) ->
    @dropdown.find selector

  toggleLoading: ->
    $('.dropdown-menu', @dropdown).toggleClass LOADING_CLASS

  togglePage: ->
    menu = $('.dropdown-menu', @dropdown)

    if menu.hasClass(PAGE_TWO_CLASS)
      if @remote
        @remote.execute()

    menu.toggleClass PAGE_TWO_CLASS

  parseData: (data) ->
    @renderedData = data

    # Render each row
    html = $.map data, (obj) =>
      return @renderItem(obj)

    if @options.filterable and data.length is 0
      # render no matching results
      html = [@noResults()]

    # Render the full menu
    full_html = @renderMenu(html.join(""))

    @appendMenu(full_html)

  shouldPropagate: (e) =>
    if @options.multiSelect
      $target = $(e.target)
      if not $target.hasClass('dropdown-menu-close') and not $target.hasClass('dropdown-menu-close-icon')
        e.stopPropagation()
        return false
      else
        return true

  opened: =>
    @addArrowKeyEvent()

    contentHtml = $('.dropdown-content', @dropdown).html()
    if @remote && contentHtml is ""
      @remote.execute()

    if @options.filterable
      @filterInput.focus()

    @dropdown.trigger('shown.gl.dropdown')

  hidden: (e) =>
    @removeArrayKeyEvent()
    if @options.filterable
      @dropdown
        .find(".dropdown-input-field")
        .blur()
        .val("")
        .trigger("keyup")

    if @dropdown.find(".dropdown-toggle-page").length
      $('.dropdown-menu', @dropdown).removeClass PAGE_TWO_CLASS

    if @options.hidden
      @options.hidden.call(@,e)

    @dropdown.trigger('hidden.gl.dropdown')


  # Render the full menu
  renderMenu: (html) ->
    menu_html = ""

    if @options.renderMenu
      menu_html = @options.renderMenu(html)
    else
      menu_html = "<ul>#{html}</ul>"

    return menu_html

  # Append the menu into the dropdown
  appendMenu: (html) ->
    selector = '.dropdown-content'
    if @dropdown.find(".dropdown-toggle-page").length
      selector = ".dropdown-page-one .dropdown-content"

    $(selector, @dropdown).html html

  # Render the row
  renderItem: (data) ->
    html = ""

    # Divider
    return "<li class='divider'></li>" if data is "divider"

    # Separator is a full-width divider
    return "<li class='separator'></li>" if data is "separator"

    # Header
    return "<li class='dropdown-header'>#{data.header}</li>" if data.header?

    if @options.renderRow
      # Call the render function
      html = @options.renderRow(data)
    else
      if not selected
        value = if @options.id then @options.id(data) else data.id
        fieldName = @options.fieldName
        field = @dropdown.parent().find("input[name='#{fieldName}'][value='#{value}']")
        if field.length
          selected = true

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

      cssClass = "";

      if selected
        cssClass = "is-active"

      if @highlight
        text = @highlightTextMatches(text, @filterInput.val())

      html = "<li>
        <a href='#{url}' class='#{cssClass}'>
          #{text}
        </a>
      </li>"

    return html

  highlightTextMatches: (text, term) ->
    occurrences = fuzzaldrinPlus.match(text, term)
    text.split('').map((character, i) ->
      if i in occurrences then "<b>#{character}</b>" else character
    ).join('')

  noResults: ->
    html = "<li class='dropdown-menu-empty-link'>
      <a href='#' class='is-focused'>
        No matching results.
      </a>
    </li>"

  highlightRow: (index) ->
    if @filterInput.val() isnt ""
      selector = '.dropdown-content li:first-child a'
      if @dropdown.find(".dropdown-toggle-page").length
        selector = ".dropdown-page-one .dropdown-content li:first-child a"

      @getElement(selector).addClass 'is-focused'

  rowClicked: (el) ->
    fieldName = @options.fieldName
    selectedIndex = el.parent().index()
    if @renderedData
      selectedObject = @renderedData[selectedIndex]
    value = if @options.id then @options.id(selectedObject, el) else selectedObject.id
    field = @dropdown.parent().find("input[name='#{fieldName}'][value='#{value}']")

    if el.hasClass(ACTIVE_CLASS)
      el.removeClass(ACTIVE_CLASS)
      field.remove()

      # Toggle the dropdown label
      if @options.toggleLabel
        $(@el).find(".dropdown-toggle-text").text @options.toggleLabel
      else
        selectedObject
    else
      if !value?
        field.remove()

      if not @options.multiSelect
        @dropdown.find(".#{ACTIVE_CLASS}").removeClass ACTIVE_CLASS
        @dropdown.parent().find("input[name='#{fieldName}']").remove()

      # Toggle active class for the tick mark
      el.addClass ACTIVE_CLASS

      # Toggle the dropdown label
      if @options.toggleLabel
        $(@el).find(".dropdown-toggle-text").text @options.toggleLabel(selectedObject)
      if value?
        if !field.length and fieldName
          # Create hidden input for form
          input = "<input type='hidden' name='#{fieldName}' value='#{value}' />"
          if @options.inputId?
            input = $(input)
                      .attr('id', @options.inputId)
          @dropdown.before input
        else
          field.val value

      return selectedObject

  selectRowAtIndex: (index) ->
    selector = ".dropdown-content li:not(.divider):eq(#{index}) a"

    if @dropdown.find(".dropdown-toggle-page").length
      selector = ".dropdown-page-one #{selector}"

    # simulate a click on the first link
    $(selector, @dropdown).trigger "click"

  addArrowKeyEvent: ->
    ARROW_KEY_CODES = [38, 40]
    $input = @dropdown.find(".dropdown-input-field")

    selector = '.dropdown-content li:not(.divider)'
    if @dropdown.find(".dropdown-toggle-page").length
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

        @highlightRowAtIndex($listItems, currentIndex) if currentIndex isnt PREV_INDEX

        return false

      if currentKeyCode is 13
        @selectRowAtIndex currentIndex

  removeArrayKeyEvent: ->
    $('body').off 'keydown'

  highlightRowAtIndex: ($listItems, index) ->
    # Remove the class for the previously focused row
    $('.is-focused', @dropdown).removeClass 'is-focused'

    # Update the class for the row at the specific index
    $listItem = $listItems.eq(index)
    $listItem.find('a:first-child').addClass "is-focused"

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

    if listItemBottom > dropdownContentBottom + dropdownScrollTop
      # Scroll the dropdown content down
      $dropdownContent.scrollTop(listItemBottom - dropdownContentBottom)
    else if listItemTop < dropdownContentTop + dropdownScrollTop
      # Scroll the dropdown content up
      $dropdownContent.scrollTop(listItemTop - dropdownContentTop)

$.fn.glDropdown = (opts) ->
  return @.each ->
    if (!$.data @, 'glDropdown')
      $.data(@, 'glDropdown', new GitLabDropdown @, opts)
