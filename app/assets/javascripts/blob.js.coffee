class BlobView
  constructor: ->
    # handle multi-line select
    handleMultiSelect = (e) ->
      [ first_line, last_line ] = parseSelectedLines()
      [ line_number ] = parseSelectedLines($(this).attr("id"))
      hash = "L#{line_number}"

      if e.shiftKey and not isNaN(first_line) and not isNaN(line_number)
        if line_number < first_line
          last_line = first_line
          first_line = line_number
        else
          last_line = line_number

        hash = if first_line == last_line then "L#{first_line}" else "L#{first_line}-#{last_line}"

      setHash(hash)
      e.preventDefault()

    # See if there are lines selected
    # "#L12" and "#L34-56" supported
    highlightBlobLines = (e) ->
      [ first_line, last_line ] = parseSelectedLines()

      unless isNaN first_line
        $("#tree-content-holder .highlight .line").removeClass("hll")
        $("#LC#{line}").addClass("hll") for line in [first_line..last_line]
        $("#L#{first_line}").ScrollTo() unless e?

    # parse selected lines from hash
    # always return first and last line (initialized to NaN)
    parseSelectedLines = (str) ->
      first_line = NaN
      last_line = NaN
      hash = str || window.location.hash

      if hash isnt ""
        matches = hash.match(/\#?L(\d+)(\-(\d+))?/)
        first_line = parseInt(matches?[1])
        last_line = parseInt(matches?[3])
        last_line = first_line if isNaN(last_line)

      [ first_line, last_line ]

    setHash = (hash) ->
      hash = hash.replace(/^\#/, "")
      nodes = $("#" + hash)
      # if any nodes are using this id, they must be temporarily changed
      # also, add a temporary div at the top of the screen to prevent scrolling
      if nodes.length > 0
        scroll_top = $(document).scrollTop()
        nodes.attr("id", "")
        tmp = $("<div></div>")
          .css({ position: "absolute", visibility: "hidden", top: scroll_top + "px" })
          .attr("id", hash)
          .appendTo(document.body)

      window.location.hash = hash

      # restore the nodes
      if nodes.length > 0
        tmp.remove()
        nodes.attr("id", hash)

    # initialize multi-line select
    $("#tree-content-holder .line-numbers a[id^=L]").on("click", handleMultiSelect)

    # Highlight the correct lines on load
    highlightBlobLines()

    # Highlight the correct lines when the hash part of the URL changes
    $(window).on("hashchange", highlightBlobLines)


@BlobView = BlobView
