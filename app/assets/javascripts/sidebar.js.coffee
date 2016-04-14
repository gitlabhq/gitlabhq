collapsed = 'page-sidebar-collapsed'
expanded = 'page-sidebar-expanded'

toggleRightSidebar =
  collapseSidebar: ->
    $gutterIcon = $('.js-sidebar-toggle i:visible')

    # Wait until listeners are set
    setTimeout( ->
      # Only when sidebar is expanded
      if $gutterIcon.is('.fa-angle-double-right')
        $gutterIcon.closest('a').trigger('click', [true])
    , 0)

  expandSidebar: ->
    return if $.cookie('collapsed_gutter') == 'true'

    $gutterIcon = $('.js-sidebar-toggle i:visible')

    # Wait until listeners are set
    setTimeout( ->
      # Only when sidebar is collapsed
      if $gutterIcon.is('.fa-angle-double-left')
        $gutterIcon.closest('a').trigger('click', [true])
    , 0)

toggleLeftSidebar = ->
  $('.page-with-sidebar').toggleClass("#{collapsed} #{expanded}")
  $('header').toggleClass("header-collapsed header-expanded")
  $('.toggle-nav-collapse i').toggleClass("fa-angle-right fa-angle-left")
  $.cookie("collapsed_nav", $('.page-with-sidebar').hasClass(collapsed), { path: '/' })

  setTimeout ( ->
    niceScrollBars = $('.nicescroll').niceScroll();
    niceScrollBars.updateScrollBar();
  ), 300

$(document).on("click", '.toggle-nav-collapse', (e) ->
  e.preventDefault()

  toggleLeftSidebar()
)

$ ->
  size = bp.getBreakpointSize()

  if size is "xs" or size is "sm"
    if $('.page-with-sidebar').hasClass(expanded)
      toggleLeftSidebar()
