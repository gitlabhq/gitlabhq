responsive_resize = ->
  current_width = $(window).width()
  if current_width < 985
    $('.responsive-side').addClass("ui right wide sidebar")
    $('.responsive-side-left').addClass("ui left sidebar")
  else
    $('.responsive-side').removeClass("ui right wide sidebar")
    $('.responsive-side-left').removeClass("ui left sidebar")

$ ->
  # Depending on window size, set the sidebar offscreen.
  responsive_resize()

  $('.ui.sidebar')
    .sidebar()

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
