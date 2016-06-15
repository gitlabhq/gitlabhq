collapsed = 'page-sidebar-collapsed'
expanded = 'page-sidebar-expanded'

toggleSidebar = ->
  $('.page-with-sidebar').toggleClass("#{collapsed} #{expanded}")
  $('.navbar-fixed-top').toggleClass("header-collapsed header-expanded")

  if $.cookie('pin_nav') is 'true'
    $('.navbar-fixed-top').toggleClass('header-pinned-nav')
    $('.page-with-sidebar').toggleClass('page-sidebar-pinned')

  setTimeout ( ->
    niceScrollBars = $('.nav-sidebar').niceScroll();
    niceScrollBars.updateScrollBar();
  ), 300

$(document).on("click", '.toggle-nav-collapse, .side-nav-toggle', (e) ->
  e.preventDefault()

  toggleSidebar()
)
