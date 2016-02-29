Turbolinks.enableProgressBar();

defaultClass = 'tanuki-shape'
pieces = [
  'path#tanuki-right-cheek',
  'path#tanuki-right-eye, path#tanuki-right-ear',
  'path#tanuki-nose',
  'path#tanuki-left-eye, path#tanuki-left-ear',
  'path#tanuki-left-cheek',
]
pieceIndex = 0
firstPiece = pieces[0]

currentTimer = null
delay        = 150

clearHighlights = ->
  $(".#{defaultClass}.highlight").attr('class', defaultClass)

start = ->
  clearHighlights()
  pieceIndex = 0
  pieces.reverse() unless pieces[0] == firstPiece
  clearInterval(currentTimer) if currentTimer
  currentTimer = setInterval(work, delay)

stop = ->
  clearInterval(currentTimer)
  clearHighlights()

work = ->
  clearHighlights()
  $(pieces[pieceIndex]).attr('class', "#{defaultClass} highlight")

  # If we hit the last piece, reset the index and then reverse the array to
  # get a nice back-and-forth sweeping look
  if pieceIndex == pieces.length - 1
    pieceIndex = 0
    pieces.reverse()
  else
    pieceIndex++

$(document).on('page:fetch',  start)
$(document).on('page:change', stop)

$ ->
  # Make logo clickable as part of a workaround for Safari visited
  # link behaviour (See !2690).
  $('#logo').on 'click', ->
    $('#js-shortcuts-home').get(0).click()
