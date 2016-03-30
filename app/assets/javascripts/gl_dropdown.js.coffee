class GitLabDropdownFilter
  BLUR_KEYCODES = [27, 40]
  HAS_VALUE_CLASS = "has-value"

  constructor: (@input, @options) ->
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
      if @input.val() isnt "" and !$inputContainer.hasClass HAS_VALUE_CLASS
        $inputContainer.addClass HAS_VALUE_CLASS
      else if @input.val() is "" and $inputContainer.hasClass HAS_VALUE_CLASS
        $inputContainer.removeClass HAS_VALUE_CLASS

      if e.keyCode is 13 and @input.val() isnt ""
        if @options.enterCallback
          @options.enterCallback()
        return

      clearTimeout timeout
      timeout = setTimeout =>
        blur_field = @shouldBlur e.keyCode
        search_text = @input.val()

        if blur_field
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

  constructor: (@el, @options) ->
    self = @
    @dropdown = $(@el).parent()
    search_fields = if @options.search then @options.search.fields else [];

    if @options.data
      # Remote data
      @remote = new GitLabDropdownRemote @options.data, {
        dataType: @options.dataType,
        beforeSend: @toggleLoading.bind(@)
        success: (data) =>
          @fullData = data

          @parseData @fullData
      }

    # Init filiterable
    if @options.filterable
      @input = @dropdown.find('.dropdown-input .dropdown-input-field')

      @filter = new GitLabDropdownFilter @input,
        remote: @options.filterRemote
        query: @options.data
        keys: @options.search.fields
        data: =>
          return @fullData
        callback: (data) =>
          @parseData data
          @highlightRow 1
        enterCallback: =>
          @selectFirstRow()

    # Event listeners
    @dropdown.on "shown.bs.dropdown", @opened
    @dropdown.on "hidden.bs.dropdown", @hidden

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
        selected = self.rowClicked $(@)

        if self.options.clicked
          self.options.clicked(selected)

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

  opened: =>
    contentHtml = $('.dropdown-content', @dropdown).html()
    if @remote && contentHtml is ""
      @remote.execute()

    if @options.filterable
      @dropdown.find(".dropdown-input-field").focus()

  hidden: =>
    if @options.filterable
      @dropdown
        .find(".dropdown-input-field")
        .blur()
        .val("")
        .trigger("keyup")

    if @dropdown.find(".dropdown-toggle-page").length
      $('.dropdown-menu', @dropdown).removeClass PAGE_TWO_CLASS


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

    return "<li class='divider'></li>" if data is "divider"

    if @options.renderRow
      # Call the render function
      html = @options.renderRow(data)
    else
      selected = if @options.isSelected then @options.isSelected(data) else false
      url = if @options.url then @options.url(data) else "#"
      text = if @options.text then @options.text(data) else ""
      cssClass = "";

      if selected
        cssClass = "is-active"

      html = "<li>"
      html += "<a href='#{url}' class='#{cssClass}'>"
      html += text
      html += "</a>"
      html += "</li>"

    return html

  noResults: ->
    html = "<li>"
    html += "<a href='#' class='dropdown-menu-empty-link is-focused'>"
    html += "No matching results."
    html += "</a>"
    html += "</li>"

  highlightRow: (index) ->
    if @input.val() isnt ""
      selector = '.dropdown-content li:first-child a'
      if @dropdown.find(".dropdown-toggle-page").length
        selector = ".dropdown-page-one .dropdown-content li:first-child a"

      $(selector).addClass 'is-focused'

  rowClicked: (el) ->
    fieldName = @options.fieldName
    selectedIndex = el.parent().index()
    if @renderedData
      selectedObject = @renderedData[selectedIndex]
    value = if @options.id then @options.id(selectedObject, el) else selectedObject.id
    field = @dropdown.parent().find("input[name='#{fieldName}']")

    if el.hasClass(ACTIVE_CLASS)
      field.remove()

      # Toggle the dropdown label
      if @options.toggleLabel
        $(@el).find(".dropdown-toggle-text").text @options.toggleLabel
    else
      if !value?
        field.remove()

      if @options.multiSelect
        oldValue = field.val()
        if oldValue
          value = "#{oldValue},#{value}"
      else
        @dropdown.find(".#{ACTIVE_CLASS}").removeClass ACTIVE_CLASS

      # Toggle active class for the tick mark
      el.addClass ACTIVE_CLASS

      # Toggle the dropdown label
      if @options.toggleLabel
        $(@el).find(".dropdown-toggle-text").text @options.toggleLabel(selectedObject)

      if value?
        if !field.length
          # Create hidden input for form
          input = "<input type='hidden' name='#{fieldName}' value='#{value}' />"
          if @options.inputId?
            input = $(input)
                      .attr('id', @options.inputId)
          @dropdown.before input

      return selectedObject

  selectFirstRow: ->
    selector = '.dropdown-content li:first-child a'
    if @dropdown.find(".dropdown-toggle-page").length
      selector = ".dropdown-page-one .dropdown-content li:first-child a"

    # simulate a click on the first link
    $(selector).trigger "click"

$.fn.glDropdown = (opts) ->
  return @.each ->
    new GitLabDropdown @, opts
