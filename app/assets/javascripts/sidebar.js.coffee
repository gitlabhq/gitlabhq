$(document).on("click", '.toggle-nav-collapse', (e) ->
  e.preventDefault()
  collapsed = 'page-sidebar-collapsed'
  expanded = 'page-sidebar-expanded'

  if $('.page-with-sidebar').hasClass(collapsed)
    $('.page-with-sidebar').removeClass(collapsed).addClass(expanded)
    $('.toggle-nav-collapse i').removeClass('fa-angle-right').addClass('fa-angle-left')
    $.cookie("collapsed_nav", "false", { path: '/' })
  else
    $('.page-with-sidebar').removeClass(expanded).addClass(collapsed)
    $('.toggle-nav-collapse i').removeClass('fa-angle-left').addClass('fa-angle-right')
    $.cookie("collapsed_nav", "true", { path: '/' })
)
