$ ->
  $('.milestone-issue-filter tr[data-closed]').addClass('hide')

  $('.milestone-issue-filter ul.nav li a').click ->
    $('.milestone-issue-filter li').toggleClass('active')
    $('.milestone-issue-filter tr[data-closed]').toggleClass('hide')
    false

  $('.milestone-merge-requests-filter tr[data-closed]').addClass('hide')

  $('.milestone-merge-requests-filter ul.nav li a').click ->
    $('.milestone-merge-requests-filter li').toggleClass('active')
    $('.milestone-merge-requests-filter tr[data-closed]').toggleClass('hide')
    false
