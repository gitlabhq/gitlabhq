class GitLabDropdownFilter
  BLUR_KEYCODES = [27, 40]

  constructor: (@dropdown, @options) ->
    @input = @dropdown.find(".dropdown-input .dropdown-input-field")

    # Key events
    timeout = ""
    @input.on "keyup", (e) =>
      if e.keyCode is 13 && @input.val() isnt ""
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
      @filter = new GitLabDropdownFilter @dropdown,
        remote: @options.filterRemote
        query: @options.data
        keys: @options.search.fields
        data: =>
          return @fullData
        callback: (data) =>
          @parseData data
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
        self.rowClicked $(@)

        if self.options.clicked
          self.options.clicked()

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
      @dropdown.find(".dropdown-input-field").blur().val("")

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
    html += "<a href='#' class='is-focused'>"
    html += "No matching results."
    html += "</a>"
    html += "</li>"

  rowClicked: (el) ->
    fieldName = @options.fieldName
    field = @dropdown.parent().find("input[name='#{fieldName}']")

    if el.hasClass(ACTIVE_CLASS)
      field.remove()
    else
      fieldName = @options.fieldName
      selectedIndex = el.parent().index()
      if @renderedData
        selectedObject = @renderedData[selectedIndex]
      value = if @options.id then @options.id(selectedObject, el) else selectedObject.id

      if @options.multiSelect
        oldValue = field.val()
        if oldValue
          value = "#{oldValue},#{value}"
      else
        @dropdown.find(ACTIVE_CLASS).removeClass ACTIVE_CLASS
        field.remove()

      # Toggle active class for the tick mark
      el.toggleClass "is-active"

      if value
        if !field.length
          # Create hidden input for form
          input = "<input type='hidden' name='#{fieldName}' />"
          @dropdown.before input

        @dropdown.parent().find("input[name='#{fieldName}']").val value

  selectFirstRow: ->
    selector = '.dropdown-content li:first-child a'
    if @dropdown.find(".dropdown-toggle-page").length
      selector = ".dropdown-page-one .dropdown-content li:first-child a"

    # similute a click on the first link
    $(selector).trigger "click"

$.fn.glDropdown = (opts) ->
  return @.each ->
    new GitLabDropdown @, opts
