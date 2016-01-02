NProgress.configure(showSpinner: false)

defaultClass = 'tanuki-shape'
highlightClass = 'highlight'
pieces = [
  'path#tanuki-right-cheek',
  'path#tanuki-right-eye, path#tanuki-right-ear',
  'path#tanuki-nose',
  'path#tanuki-left-eye, path#tanuki-left-ear',
  'path#tanuki-left-cheek',
]
timeout = null

clearHighlights = ->
  $(".#{defaultClass}").attr('class', defaultClass)

start = ->
  clearHighlights()
  work(0)

stop = ->
  window.clearTimeout(timeout)
  clearHighlights()

work = (pieceIndex) =>
  # jQuery's addClass won't work on an SVG. Who knew!
  $piece = $(pieces[pieceIndex])
  $piece.attr('class', "#{defaultClass} #{highlightClass}")

  timeout = setTimeout(=>
    $piece.attr('class', defaultClass)

    # If we hit the last piece, reset the index and then reverse the array to
    # get a nice back-and-forth sweeping look
    if pieceIndex + 1 >= pieces.length
      nextIndex = 0
      pieces.reverse()
    else
      nextIndex = pieceIndex + 1

    work(nextIndex)
  , 200)

$(document).on 'page:fetch',  start
$(document).on 'page:change', stop
