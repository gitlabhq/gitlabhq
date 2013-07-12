class BlobView
  constructor: ->
    # See if there are lines selected
    # "#L12" and "#L34-56" supported
    highlightBlobLines = ->
      if window.location.hash isnt ""
        matches = window.location.hash.match(/\#L(\d+)(\-(\d+))?/)
        first_line = parseInt(matches?[1])
        last_line = parseInt(matches?[3])

        unless isNaN first_line
          last_line = first_line if isNaN(last_line)
          $("#tree-content-holder .highlight .line").removeClass("hll")
          $("#LC#{line}").addClass("hll") for line in [first_line..last_line]
          $("#L#{first_line}").ScrollTo()

    # Highlight the correct lines on load
    highlightBlobLines()

    # Highlight the correct lines when the hash part of the URL changes
    $(window).on 'hashchange', highlightBlobLines


@BlobView = BlobView
