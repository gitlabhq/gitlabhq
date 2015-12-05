class @ProjectFindFile
  constructor: (@options)->
    @filePathes = {}
    @element = ".tree-filter-input"
    @row = "<tr class='tree-item'><td class='tree-item-file-name'><i class='fa fa-file-text-o fa-fw'></i><span class='str-truncated'><a href=%blobItemUrl>%filePath</a></span></td></tr>"

    # focus text input box
    $(".tree-filter-input").focus()

    # bind keyup event at text input box
    $(document).off "keyup"
    $(document).off "keyup", ".tree-filter-input"
    $(document).on "keyup", @goBack
    $(document).on "keyup", ".tree-filter-input", (event) =>
      @findFile(event)

    @load(@options.url)

  # files pathes load
  load: (url) ->
    $.ajax
      url: url
      method: "get"
      dataType: "json"
      success: $.proxy((data) ->
        $(".loading").hide()
        @filePathes = data
        @renderList(@filePathes)
      , this)

  # render result
  renderList: (filePathes, searchTxt) ->
    $(".tree-table > tbody").empty()
    for filePath, i in filePathes
      break if i > 20
      markedFilePath = if searchTxt then highlightText filePath, searchTxt.split("") else filePath
      blobItemUrl = "#{@options.blob_url_template}/#{filePath}"
      html = @makeHtml markedFilePath, blobItemUrl
      $(".tree-table > tbody").append(html)

  makeHtml: (filePath, blobItemUrl) ->
    return  @row.replace("%blobItemUrl", blobItemUrl).replace("%filePath", filePath)

  # highlight text(awefwbwgtc -> <b>a</b>wefw<b>b</b>wgt<b>c</b> )
  highlightText = (txt, charArr) ->
    result = ""
    target = txt.toString()
    for char in charArr
      charIdx = target.toLowerCase().indexOf char.toLowerCase()
      result += "#{target.substring 0, charIdx}#{(target.charAt charIdx).bold()}"
      target = target.substring charIdx + 1
    return (result + target)

  # find file
  findFile: (event) ->
      # esc 27 caps 20 ctrl 17 alt 18 shift 16 enter 13 cmd 91
    keyCode = event.keyCode
    if keyCode != 20 && keyCode != 17 && keyCode != 18 && keyCode != 16 && keyCode != 13 && keyCode != 91
      searchTxt = $(@element).val()
      result = if searchTxt then fuzzaldrinPlus.filter(@filePathes, searchTxt) else @filePathes
      @renderList result, searchTxt

  # go back page
  goBack: (event) ->
    if event.keyCode == 27
      event.preventdefault
      parent.history.back()
    return false;
