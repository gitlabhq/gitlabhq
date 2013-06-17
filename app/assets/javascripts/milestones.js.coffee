$ ->
  $('.milestone-merge-requests-filter li[data-closed]').addClass('hide')

  $('.milestone-merge-requests-filter ul.nav li a').click ->
    $('.milestone-merge-requests-filter li').toggleClass('active')
    $('.milestone-merge-requests-filter li[data-closed]').toggleClass('hide')
    false
