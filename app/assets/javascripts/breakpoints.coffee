class @Breakpoints
  BREAKPOINTS = ["xs", "sm", "md", "lg"]

  constructor: ->
    @setup()

  setup: ->
    allDeviceSelector = BREAKPOINTS.map (breakpoint) ->
      ".device-#{breakpoint}"

    if $(allDeviceSelector.join(",")).length
      return

    # Create all the elements
    $.each BREAKPOINTS, (i, breakpoint) ->
      $("body").append "<div class='device-#{breakpoint} visible-#{breakpoint}'></div>"

  getBreakpointSize: ->
    allDeviceSelector = BREAKPOINTS.map (breakpoint) ->
      ".device-#{breakpoint}"

    $visibleDevice = $(allDeviceSelector.join(",")).filter(":visible")
    
    return $visibleDevice.attr("class").split("visible-")[1]
