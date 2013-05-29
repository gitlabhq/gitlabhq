# Code browser tree slider
# Make the entire tree-item row clickable, but not if clicking another link (like a commit message)
$(".tree-content-holder .tree-item").live 'click', (e) ->
  if (e.target.nodeName != "A")
    path = $('.tree-item-file-name a', this).attr('href')
    Turbolinks.visit(path)

$ ->
  # Show the "Loading commit data" for only the first element
  $('span.log_loading:first').removeClass('hide')

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
