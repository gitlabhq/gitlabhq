$(document).on 'click', '.badge-codes-toggle', ->
  $('.badge-codes-block').toggleClass("hide")
  return false

$(document).on 'click', '.sync-now', ->
  $(this).find('i').addClass('fa-spin')
