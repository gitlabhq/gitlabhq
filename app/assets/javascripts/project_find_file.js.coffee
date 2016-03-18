class @ProjectFindFile
  constructor: (@element, @options)->
    @filePaths = {}
    @inputElement = @element.find(".file-finder-input")

    # init event
    @initEvent()

    # focus text input box
    @inputElement.focus()

    # load file list
    @load(@options.url)

  # init event
  initEvent: ->
    @inputElement.off "keyup"
    @inputElement.on "keyup", (event) =>
      target = $(event.target)
      value = target.val()
      oldValue = target.data("oldValue") ? ""

      if value != oldValue
        target.data("oldValue", value)
        @findFile()
        @element.find("tr.tree-item").eq(0).addClass("selected").focus()

    @element.find(".tree-content-holder .tree-table").on "click", (event) ->
      if (event.target.nodeName != "A")
        path = @element.find(".tree-item-file-name a", this).attr("href")
        location.href = path if path

  # find file
  findFile: ->
    searchText = @inputElement.val()
    result = if searchText.length > 0 then fuzzaldrinPlus.filter(@filePaths, searchText) else @filePaths
    @renderList result, searchText

  # files pathes load
  load: (url) ->
    $.ajax
      url: url
      method: "get"
      dataType: "json"
      success: (data) =>
        @element.find(".loading").hide()
        @filePaths = data
        @findFile()
        @element.find(".files-slider tr.tree-item").eq(0).addClass("selected").focus()

  # render result
  renderList: (filePaths, searchText) ->
    @element.find(".tree-table > tbody").empty()

    for filePath, i in filePaths
      break if i == 20

      if searchText
        matches = fuzzaldrinPlus.match(filePath, searchText)

      blobItemUrl = "#{@options.blobUrlTemplate}/#{filePath}"

      html = @makeHtml filePath, matches, blobItemUrl
      @element.find(".tree-table > tbody").append(html)

  # highlight text(awefwbwgtc -> <b>a</b>wefw<b>b</b>wgt<b>c</b> )
  highlighter = (element, text, matches) ->
    lastIndex = 0
    highlightText = ""
    matchedChars = []

    for matchIndex in matches
      unmatched = text.substring(lastIndex, matchIndex)

      if unmatched
        element.append(matchedChars.join("").bold()) if matchedChars.length
        matchedChars = []
        element.append(document.createTextNode(unmatched))

      matchedChars.push(text[matchIndex])
      lastIndex = matchIndex + 1

    element.append(matchedChars.join("").bold()) if matchedChars.length
    element.append(document.createTextNode(text.substring(lastIndex)))

  # make tbody row html
  makeHtml: (filePath, matches, blobItemUrl) ->
    $tr = $("<tr class='tree-item'><td class='tree-item-file-name'><i class='fa fa-file-text-o fa-fw'></i><span class='str-truncated'><a></a></span></td></tr>")
    if matches
      $tr.find("a").replaceWith(highlighter($tr.find("a"), filePath, matches).attr("href", blobItemUrl))
    else
      $tr.find("a").attr("href", blobItemUrl).text(filePath)

    return $tr

  selectRow: (type) ->
    rows = @element.find(".files-slider tr.tree-item")
    selectedRow = @element.find(".files-slider tr.tree-item.selected")

    if rows && rows.length > 0
      if selectedRow && selectedRow.length > 0
        if type == "UP"
          next = selectedRow.prev()
        else if type == "DOWN"
          next = selectedRow.next()

        if next.length > 0
          selectedRow.removeClass "selected"
          selectedRow = next
      else
        selectedRow = rows.eq(0)
      selectedRow.addClass("selected").focus()

  selectRowUp: =>
    @selectRow "UP"

  selectRowDown: =>
    @selectRow "DOWN"

  goToTree: =>
    location.href = @options.treeUrl

  goToBlob: =>
    path = @element.find(".tree-item.selected .tree-item-file-name a").attr("href")
    location.href = path if path
