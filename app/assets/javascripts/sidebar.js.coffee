responsive_resize = ->
  current_width = $(window).width()
  if current_width < 385
    $('.responsive-side').removeClass("wide").addClass("ui right sidebar")
  else if current_width < 985
    $('.responsive-side').addClass("ui right wide sidebar")
  else
    $('.responsive-side').removeClass("ui right wide sidebar")

hide_sidebar = (e) ->
  container = $(".ui.sidebar")
  container.sidebar "hide"  if not container.is(e.target) and container.has(e.target).length is 0
  return

$ ->
  # Depending on window size, set the sidebar offscreen.
  responsive_resize()

  $('.sidebar-expand-button').click ->
    $('.ui.sidebar')
      .sidebar({overlay: true})
      .sidebar('toggle')

  # Hide sidebar on click outside of sidebar
  $(document).on('touchend', hide_sidebar).mouseup(hide_sidebar)

# On resize, check if sidebar should be offscreen.
$(window).resize ->
  responsive_resize()
  return
