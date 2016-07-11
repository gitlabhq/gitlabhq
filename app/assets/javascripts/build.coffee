class @Build
  @interval: null
  @state: null

  constructor: (@page_url, @build_url, @build_status, @state) ->
    clearInterval(Build.interval)

    # Init breakpoint checker
    @bp = Breakpoints.get()
    @hideSidebar()
    $('.js-build-sidebar').niceScroll()
    $(document)
      .off 'click', '.js-sidebar-build-toggle'
      .on 'click', '.js-sidebar-build-toggle', @toggleSidebar

    $(window)
      .off 'resize.build'
      .on 'resize.build', @hideSidebar

    @updateArtifactRemoveDate()

    if $('#build-trace').length
      @getInitialBuildTrace()
      @initScrollButtonAffix()

    if @build_status is "running" or @build_status is "pending"
      #
      # Bind autoscroll button to follow build output
      #
      $('#autoscroll-button').on 'click', ->
        state = $(this).data("state")
        if "enabled" is state
          $(this).data "state", "disabled"
          $(this).text "enable autoscroll"
        else
          $(this).data "state", "enabled"
          $(this).text "disable autoscroll"

      #
      # Check for new build output if user still watching build page
      # Only valid for runnig build when output changes during time
      #
      Build.interval = setInterval =>
        if window.location.href.split("#").first() is @page_url
          @getBuildTrace()
      , 4000

  getInitialBuildTrace: ->
    $.ajax
      url: @build_url
      dataType: 'json'
      success: (build_data) ->
        $('.js-build-output').html build_data.trace_html

        if build_data.status is 'success' or build_data.status is 'failed'
          $('.js-build-refresh').remove()

  getBuildTrace: ->
    $.ajax
      url: "#{@page_url}/trace.json?state=#{encodeURIComponent(@state)}"
      dataType: "json"
      success: (log) =>
        if log.state
          @state = log.state

        if log.status is "running"
          if log.append
            $('.js-build-output').append log.html
          else
            $('.js-build-output').html log.html
          @checkAutoscroll()
        else if log.status isnt @build_status
          Turbolinks.visit @page_url

  checkAutoscroll: ->
    $("html,body").scrollTop $("#build-trace").height()  if "enabled" is $("#autoscroll-button").data("state")

  initScrollButtonAffix: ->
    $buildScroll = $('#js-build-scroll')
    $body = $('body')
    $buildTrace = $('#build-trace')

    $buildScroll.affix(
      offset:
        bottom: ->
          $body.outerHeight() - ($buildTrace.outerHeight() + $buildTrace.offset().top)
    )

  shouldHideSidebar: ->
    bootstrapBreakpoint = @bp.getBreakpointSize()

    bootstrapBreakpoint is 'xs' or bootstrapBreakpoint is 'sm'

  toggleSidebar: =>
    if @shouldHideSidebar()
      $('.js-build-sidebar')
        .toggleClass 'right-sidebar-expanded right-sidebar-collapsed'

  hideSidebar: =>
    if @shouldHideSidebar()
      $('.js-build-sidebar')
        .removeClass 'right-sidebar-expanded'
        .addClass 'right-sidebar-collapsed'
    else
      $('.js-build-sidebar')
        .removeClass 'right-sidebar-collapsed'
        .addClass 'right-sidebar-expanded'

  updateArtifactRemoveDate: ->
    $date = $('.js-artifacts-remove')

    if $date.length
      date = $date.text()
      $date.text $.timefor(new Date(date), ' ')
