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

$(document)
  .off 'click', 'body'
  .on 'click', 'body', (e) ->
    unless $.cookie('pin_nav') is 'true'
      $target = $(e.target)
      $nav = $target.closest('.sidebar-wrapper')
      pageExpanded = $('.page-with-sidebar').hasClass('page-sidebar-expanded')
      $toggle = $target.closest('.toggle-nav-collapse, .side-nav-toggle')

      if $nav.length is 0 and pageExpanded and $toggle.length is 0
        $('.page-with-sidebar')
          .toggleClass('page-sidebar-collapsed page-sidebar-expanded')

        $('.navbar-fixed-top')
          .toggleClass('header-collapsed header-expanded')

$(document).on("click", '.toggle-nav-collapse, .side-nav-toggle', (e) ->
  e.preventDefault()

  toggleSidebar()
)
