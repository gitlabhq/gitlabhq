# Code browser tree slider

$ ->
  if $('#tree-slider').length > 0
    # Show the "Loading commit data" for only the first element
    $('span.log_loading:first').removeClass('hide')

    $('#tree-slider .tree-item-file-name a, .breadcrumb li > a').live "click", ->
      $("#tree-content-holder").hide("slide", { direction: "left" }, 150)

    # Make the entire tree-item row clickable, but not if clicking another link (like a commit message)
    $("#tree-slider .tree-item").live 'click', (e) ->
      $('.tree-item-file-name a', this).trigger('click') if (e.target.nodeName != "A")

    # Show/Hide the loading spinner
    $('#tree-slider .tree-item-file-name a, .breadcrumb a, .project-refs-form').live
      "ajax:beforeSend": -> $('.tree_progress').addClass("loading")
      "ajax:complete":   -> $('.tree_progress').removeClass("loading")

    # Maintain forward/back history while browsing the file tree
    ((window) ->
      History = window.History
      $ = window.jQuery
      document = window.document

      # Check to see if History.js is enabled for our Browser
      unless History.enabled
        return false

      $('#tree-slider .tree-item-file-name a, .breadcrumb li > a').live 'click', (e) ->
        History.pushState(null, null, decodeURIComponent($(@).attr('href')))
        return false

      History.Adapter.bind window, 'statechange', ->
        state = History.getState()
        window.ajaxGet(state.url)
    )(window)

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
