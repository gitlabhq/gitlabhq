class CiBuild
  @interval: null
  @state: null

  constructor: (build_url, build_status, build_state) ->
    clearInterval(CiBuild.interval)

    @state = build_state

    @initScrollButtonAffix()

    if build_status == "running" || build_status == "pending"
      #
      # Bind autoscroll button to follow build output
      #
      $("#autoscroll-button").bind "click", ->
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
      CiBuild.interval = setInterval =>
        if window.location.href.split("#").first() is build_url
          last_state = @state
          $.ajax
            url: build_url + "/trace.json?state=" + encodeURIComponent(@state)
            dataType: "json"
            success: (log) =>
              return unless last_state is @state

              if log.state and log.status is "running"
                @state = log.state
                if log.append
                  $('.fa-refresh').before log.html
                else
                  $('#build-trace code').html log.html
                  $('#build-trace code').append '<i class="fa fa-refresh fa-spin"/>'
                @checkAutoscroll()
              else if log.status isnt build_status
                Turbolinks.visit build_url
      , 4000

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

@CiBuild = CiBuild
