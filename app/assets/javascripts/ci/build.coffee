class CiBuild
  @interval: null

  constructor: (build_url, build_status) ->
    clearInterval(CiBuild.interval)

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
          $.ajax
            url: build_url
            dataType: "json"
            success: (build) =>
              if build.status == "running"
                $('#build-trace code').html build.trace_html
                $('#build-trace code').append '<i class="fa fa-refresh fa-spin"/>'
                @checkAutoscroll()
              else
                Turbolinks.visit build_url
      , 4000

  checkAutoscroll: ->
    $("html,body").scrollTop $("#build-trace").height()  if "enabled" is $("#autoscroll-button").data("state")

@CiBuild = CiBuild
