collapsed = 'page-sidebar-collapsed'
expanded = 'page-sidebar-expanded'

toggleSidebar = ->
  $('.page-with-sidebar').toggleClass("#{collapsed} #{expanded}")
  $('header').toggleClass("header-collapsed header-expanded")

  setTimeout ( ->
    niceScrollBars = $('.nicescroll').niceScroll();
    niceScrollBars.updateScrollBar();
  ), 300

$(document).on("click", '.toggle-nav-collapse, .side-nav-toggle', (e) ->
  e.preventDefault()

  toggleSidebar()
)
