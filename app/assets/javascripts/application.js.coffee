# This is a manifest file that'll be compiled into including all the files listed below.
# Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
# be included in the compiled file accessible from http://example.com/assets/application.js
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
#= require jquery2
#= require jquery-ui/autocomplete
#= require jquery-ui/datepicker
#= require jquery-ui/draggable
#= require jquery-ui/effect-highlight
#= require jquery-ui/sortable
#= require jquery_ujs
#= require jquery.cookie
#= require jquery.endless-scroll
#= require jquery.highlight
#= require jquery.waitforimages
#= require jquery.atwho
#= require jquery.scrollTo
#= require jquery.turbolinks
#= require jquery.tablesorter
#= require turbolinks
#= require autosave
#= require bootstrap/affix
#= require bootstrap/alert
#= require bootstrap/button
#= require bootstrap/collapse
#= require bootstrap/dropdown
#= require bootstrap/modal
#= require bootstrap/scrollspy
#= require bootstrap/tab
#= require bootstrap/transition
#= require bootstrap/tooltip
#= require bootstrap/popover
#= require select2
#= require ace/ace
#= require ace/ext-searchbox
#= require underscore
#= require dropzone
#= require mousetrap
#= require mousetrap/pause
#= require shortcuts
#= require shortcuts_navigation
#= require shortcuts_dashboard_navigation
#= require shortcuts_issuable
#= require shortcuts_network
#= require jquery.nicescroll
#= require date.format
#= require_directory ./behaviors
#= require_directory ./blob
#= require_directory ./commit
#= require_directory ./extensions
#= require_directory ./lib/utils
#= require_directory ./u2f
#= require_directory .
#= require fuzzaldrin-plus

window.slugify = (text) ->
  text.replace(/[^-a-zA-Z0-9]+/g, '_').toLowerCase()

window.ajaxGet = (url) ->
  $.ajax({type: "GET", url: url, dataType: "script"})

window.split = (val) ->
  return val.split( /,\s*/ )

window.extractLast = (term) ->
  return split( term ).pop()

window.rstrip = (val) ->
  return if val then val.replace(/\s+$/, '') else val

# Disable button if text field is empty
window.disableButtonIfEmptyField = (field_selector, button_selector) ->
  field = $(field_selector)
  closest_submit = field.closest('form').find(button_selector)

  closest_submit.disable() if rstrip(field.val()) is ""

  field.on 'input', ->
    if rstrip($(@).val()) is ""
      closest_submit.disable()
    else
      closest_submit.enable()

# Disable button if any input field with given selector is empty
window.disableButtonIfAnyEmptyField = (form, form_selector, button_selector) ->
  closest_submit = form.find(button_selector)
  updateButtons = ->
    filled = true
    form.find('input').filter(form_selector).each ->
      filled = rstrip($(this).val()) != "" || !$(this).attr('required')

    if filled
      closest_submit.enable()
    else
      closest_submit.disable()

  updateButtons()
  form.keyup(updateButtons)

window.sanitize = (str) ->
  return str.replace(/<(?:.|\n)*?>/gm, '')

window.unbindEvents = ->
  $(document).off('scroll')

window.shiftWindow = ->
  scrollBy 0, -100

document.addEventListener("page:fetch", unbindEvents)

window.addEventListener "hashchange", shiftWindow

$.timeago.settings.allowFuture = true

window.onload = ->
  # Scroll the window to avoid the topnav bar
  # https://github.com/twitter/bootstrap/issues/1768
  if location.hash
    setTimeout shiftWindow, 100

$ ->

  $document = $(document)
  $window   = $(window)
  $body     = $('body')

  gl.utils.preventDisabledButtons()
  bootstrapBreakpoint = bp.getBreakpointSize()

  $(".nav-sidebar").niceScroll(cursoropacitymax: '0.4', cursorcolor: '#FFF', cursorborder: "1px solid #FFF")

  # Click a .js-select-on-focus field, select the contents
  $(".js-select-on-focus").on "focusin", ->
    # Prevent a mouseup event from deselecting the input
    $(this).select().one 'mouseup', (e) ->
      e.preventDefault()

  $('.remove-row').bind 'ajax:success', ->
    $(this).closest('li').fadeOut()

  $('.js-remove-tr').bind 'ajax:before', ->
    $(this).hide()

  $('.js-remove-tr').bind 'ajax:success', ->
    $(this).closest('tr').fadeOut()

  # Initialize select2 selects
  $('select.select2').select2(width: 'resolve', dropdownAutoWidth: true)

  # Close select2 on escape
  $('.js-select2').bind 'select2-close', ->
    setTimeout ( ->
      $('.select2-container-active').removeClass('select2-container-active')
      $(':focus').blur()
    ), 1

  # Initialize tooltips
  $body.tooltip(
    selector: '.has-tooltip, [data-toggle="tooltip"]'
    placement: (_, el) ->
      $el = $(el)
      $el.data('placement') || 'bottom'
  )

  # Form submitter
  $('.trigger-submit').on 'change', ->
    $(@).parents('form').submit()

  gl.utils.localTimeAgo($('abbr.timeago, .js-timeago'), true)

  # Flash
  if (flash = $(".flash-container")).length > 0
    flash.click -> $(@).fadeOut()
    flash.show()

  # Disable form buttons while a form is submitting
  $body.on 'ajax:complete, ajax:beforeSend, submit', 'form', (e) ->
    buttons = $('[type="submit"]', @)

    switch e.type
      when 'ajax:beforeSend', 'submit'
        buttons.disable()
      else
        buttons.enable()

  $(document).ajaxError (e, xhrObj, xhrSetting, xhrErrorText) ->

    if xhrObj.status is 401
      new Flash 'You need to be logged in.', 'alert'

    else if xhrObj.status in [ 404, 500 ]
      new Flash 'Something went wrong on our end.', 'alert'


  # Show/Hide the profile menu when hovering the account box
  $('.account-box').hover -> $(@).toggleClass('hover')

  # Commit show suppressed diff
  $document.on 'click', '.diff-content .js-show-suppressed-diff', ->
    $container = $(@).parent()
    $container.next('table').show()
    $container.remove()

  $('.navbar-toggle').on 'click', ->
    $('.header-content .title').toggle()
    $('.header-content .header-logo').toggle()
    $('.header-content .navbar-collapse').toggle()
    $('.navbar-toggle').toggleClass('active')

  # Show/hide comments on diff
  $body.on "click", ".js-toggle-diff-comments", (e) ->
    $(@).toggleClass('active')
    $(@).closest(".diff-file").find(".notes_holder").toggle()
    e.preventDefault()

  $document.off "click", '.js-confirm-danger'
  $document.on "click", '.js-confirm-danger', (e) ->
    e.preventDefault()
    btn = $(e.target)
    text = btn.data("confirm-danger-message")
    warningMessage = btn.data("warning-message")
    form = btn.closest("form")
    new ConfirmDangerModal(form, text, warningMessage: warningMessage)


  $document.on 'click', 'button', ->
    $(this).blur()

  $('input[type="search"]').each ->
    $this = $(this)
    $this.attr 'value', $this.val()
    return

  $document
    .off 'keyup', 'input[type="search"]'
    .on 'keyup', 'input[type="search"]' , (e) ->
      $this = $(this)
      $this.attr 'value', $this.val()

  $sidebarGutterToggle = $('.js-sidebar-toggle')

  $document
    .off 'breakpoint:change'
    .on 'breakpoint:change', (e, breakpoint) ->
      if breakpoint is 'sm' or breakpoint is 'xs'
        $gutterIcon = $sidebarGutterToggle.find('i')
        if $gutterIcon.hasClass('fa-angle-double-right')
          $sidebarGutterToggle.trigger('click')

  fitSidebarForSize = ->
    oldBootstrapBreakpoint = bootstrapBreakpoint
    bootstrapBreakpoint = bp.getBreakpointSize()
    if bootstrapBreakpoint != oldBootstrapBreakpoint
      $document.trigger('breakpoint:change', [bootstrapBreakpoint])

  checkInitialSidebarSize = ->
    bootstrapBreakpoint = bp.getBreakpointSize()
    if bootstrapBreakpoint is "xs" or "sm"
      $document.trigger('breakpoint:change', [bootstrapBreakpoint])

  $window
    .off "resize.app"
    .on "resize.app", (e) ->
      fitSidebarForSize()

  gl.awardsHandler = new AwardsHandler()
  checkInitialSidebarSize()
  new Aside()

  # Sidenav pinning
  if $window.width() < 1024 and $.cookie('pin_nav') is 'true'
    $.cookie('pin_nav', 'false', { path: '/', expires: 365 * 10 })
    $('.page-with-sidebar')
      .toggleClass('page-sidebar-collapsed page-sidebar-expanded')
      .removeClass('page-sidebar-pinned')
    $('.navbar-fixed-top').removeClass('header-pinned-nav')

  $document
    .off 'click', '.js-nav-pin'
    .on 'click', '.js-nav-pin', (e) ->
      e.preventDefault()

      $pinBtn = $(e.currentTarget)
      $page = $ '.page-with-sidebar'
      $topNav = $ '.navbar-fixed-top'
      $tooltip = $ "##{$pinBtn.attr('aria-describedby')}"
      doPinNav = not $page.is('.page-sidebar-pinned')
      tooltipText = 'Pin navigation'

      $(this).toggleClass 'is-active'

      if doPinNav
        $page.addClass('page-sidebar-pinned')
        $topNav.addClass('header-pinned-nav')
      else
        $tooltip.remove() # Remove it immediately when collapsing the sidebar
        $page.removeClass('page-sidebar-pinned')
             .toggleClass('page-sidebar-collapsed page-sidebar-expanded')
        $topNav.removeClass('header-pinned-nav')
               .toggleClass('header-collapsed header-expanded')

      # Save settings
      $.cookie 'pin_nav', doPinNav, { path: '/', expires: 365 * 10 }

      if $.cookie('pin_nav') is 'true' or doPinNav
        tooltipText = 'Unpin navigation'

      # Update tooltip text immediately
      $tooltip.find('.tooltip-inner').text(tooltipText)

      # Persist tooltip title
      $pinBtn.attr('title', tooltipText).tooltip('fixTitle')
