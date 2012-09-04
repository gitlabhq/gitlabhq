$ ->
  $('.milestone-issue-filter td[data-closed]').addClass('hide')

  $('.milestone-issue-filter ul.nav li a').click ->
    $('.milestone-issue-filter li').toggleClass('active')
    $('.milestone-issue-filter td[data-closed]').toggleClass('hide')
    false
