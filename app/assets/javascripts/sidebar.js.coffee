#= require jquery.cookie

leftSidebarCollapsed = 'page-sidebar-collapsed'
leftSidebarExpanded = 'page-sidebar-expanded'

@issuableSidebar =
  init: ->
    issuableSidebar.initLeftSidebarClick()

    size = bp.getBreakpointSize() if bp?

    if size is "xs" or size is "sm"
      if $('.page-with-sidebar').hasClass(leftSidebarExpanded)
        @toggleLeftSidebar()

  initLeftSidebarClick: ->
    $(document).on("click", '.toggle-nav-collapse', (e) =>
      e.preventDefault()

      @toggleLeftSidebar()
    )

  getGutterState: () ->
    $.cookie('collapsed_gutter')

  collapseRightSidebar: ->
    if bp? and bp.getBreakpointSize() isnt 'lg'
      $gutterIcon = $('.js-sidebar-toggle i:visible')

      # Wait until listeners are set
      setTimeout( ->
        # Only when sidebar is expanded
        if $gutterIcon.is('.fa-angle-double-right')
          $gutterIcon.closest('a').trigger('click', [true])
      , 0)

  expandRightSidebar: ->
    return if @getGutterState() == 'true'

    $gutterIcon = $('.js-sidebar-toggle i:visible')

    # Wait until listeners are set
    setTimeout( ->
      # Only when sidebar is collapsed
      if $gutterIcon.is('.fa-angle-double-left')
        $gutterIcon.closest('a').trigger('click', [true])
    , 0)

  toggleLeftSidebar: ->
    $('.page-with-sidebar').toggleClass("#{leftSidebarCollapsed} #{leftSidebarExpanded}")
    $('header').toggleClass("header-collapsed header-expanded")
    $('.toggle-nav-collapse i').toggleClass("fa-angle-right fa-angle-left")
    $.cookie("collapsed_nav", $('.page-with-sidebar').hasClass(leftSidebarCollapsed), { path: '/' })

    setTimeout ( ->
      niceScrollBars = $('.nicescroll').niceScroll();
      niceScrollBars.updateScrollBar();
    ), 300

$ ->
  issuableSidebar.init()
