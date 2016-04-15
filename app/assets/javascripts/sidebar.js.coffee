#= require jquery.cookie

leftSidebarCollapsed = 'page-sidebar-collapsed'
leftSidebarExpanded = 'page-sidebar-expanded'

@RightSidebar =
  # set gutter state to one of this two values "expanded_gutter" or "collapsed_gutter"
  setGutterState: (state) ->
    gutterState = undefined
    if state = 'expanded_gutter'
      gutterState = 'right-sidebar-expanded'
    else if state = 'collapsed_gutter'
      gutterState = 'right-sidebar-collapsed'
    else
      throw new Error 'Unexpected argument, expected "expanded_gutter" or "collapsed_gutter"'

    $.cookie(state, $('.page-with-sidebar').hasClass(gutterState), { path: '/' })

  # "expanded_gutter" or "collapsed_gutter"
  getGutterState: (state) ->
    if state is 'expanded_gutter' or state is 'collapsed_gutter'
      $.cookie(state)
    else
      throw new Error 'Unexpected argument, expected "expanded_gutter" or "collapsed_gutter"'

  collapseSidebar: ->
    if bp? and bp.getBreakpointSize() isnt 'lg'
      $gutterIcon = $('.js-sidebar-toggle i:visible')

      # Wait until listeners are set
      setTimeout( ->
        # Only when sidebar is expanded
        if $gutterIcon.is('.fa-angle-double-right')
          $gutterIcon.closest('a').trigger('click', [true])
      , 0)

  expandSidebar: ->
    return if @getGutterState('collapsed_gutter') == 'true'

    $gutterIcon = $('.js-sidebar-toggle i:visible')

    # Wait until listeners are set
    setTimeout( ->
      # Only when sidebar is collapsed
      if $gutterIcon.is('.fa-angle-double-left')
        $gutterIcon.closest('a').trigger('click', [true])
    , 0)

toggleLeftSidebar = ->
  $('.page-with-sidebar').toggleClass("#{leftSidebarCollapsed} #{leftSidebarExpanded}")
  $('header').toggleClass("header-collapsed header-expanded")
  $('.toggle-nav-collapse i').toggleClass("fa-angle-right fa-angle-left")
  $.cookie("collapsed_nav", $('.page-with-sidebar').hasClass(leftSidebarCollapsed), { path: '/' })

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
    if $('.page-with-sidebar').hasClass(leftSidebarExpanded)
      toggleLeftSidebar()
