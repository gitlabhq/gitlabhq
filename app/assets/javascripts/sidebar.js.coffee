responsive_resize = ->
  current_width = $(window).width()
  if current_width < 985
    $('.responsive-side').addClass("ui right wide sidebar")
  else
    $('.responsive-side').removeClass("ui right wide sidebar")

$ ->
  # Depending on window size, set the sidebar offscreen.
  responsive_resize()

  $('.sidebar-expand-button').click ->
    $('.ui.sidebar')
      .sidebar({overlay: true})
      .sidebar('toggle')

  # Hide sidebar on click outside of sidebar
  $(document).mouseup (e) ->
    container = $(".ui.sidebar")
    container.sidebar "hide"  if not container.is(e.target) and container.has(e.target).length is 0
    return

# On resize, check if sidebar should be offscreen.
$(window).resize ->
  responsive_resize()
  return

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
