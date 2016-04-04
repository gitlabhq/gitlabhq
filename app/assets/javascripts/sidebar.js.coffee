collapsed = 'page-sidebar-collapsed'
expanded = 'page-sidebar-expanded'

toggleSidebar = ->
  $('.nicescroll').getNiceScroll().remove()
  $('.sidebar-wrapper').css('overflow-y','hidden')
  $('.page-with-sidebar').toggleClass("#{collapsed} #{expanded}")
  $('header').toggleClass("header-collapsed header-expanded")
  $('.toggle-nav-collapse i').toggleClass("fa-angle-right fa-angle-left")
  $.cookie("collapsed_nav", $('.page-with-sidebar').hasClass(collapsed), { path: '/' })

  setTimeout ( ->
    $(".nicescroll").niceScroll(cursoropacitymax: '0.4', cursorcolor: '#FFF', cursorborder: "1px solid #FFF")
  ), 300

$(document).on("click", '.toggle-nav-collapse', (e) ->
  e.preventDefault()
  toggleSidebar()
)

$ ->
  size = bp.getBreakpointSize()

  if size is "xs" or size is "sm"
    if $('.page-with-sidebar').hasClass(expanded)
      toggleSidebar()
