initGraphNav = ->
  $('.graph svg').css 'position', 'relative'

  $('body').bind 'keyup', (e) ->
    if e.keyCode is 37 # left
      $('.graph svg').animate left: '+=400'
    else if e.keyCode is 39 # right
      $('.graph svg').animate left: '-=400'

window.initGraphNav = initGraphNav
