class @Breakpoints
  instance = null;

  class BreakpointInstance
    BREAKPOINTS = ["xs", "sm", "md", "lg"]

    constructor: ->
      @setup()

    setup: ->
      allDeviceSelector = BREAKPOINTS.map (breakpoint) ->
        ".device-#{breakpoint}"
      return if $(allDeviceSelector.join(",")).length

      # Create all the elements
      els = $.map BREAKPOINTS, (breakpoint) ->
        "<div class='device-#{breakpoint} visible-#{breakpoint}'></div>"
      $("body").append els.join('')

    visibleDevice: ->
      allDeviceSelector = BREAKPOINTS.map (breakpoint) ->
        ".device-#{breakpoint}"
      $(allDeviceSelector.join(",")).filter(":visible")

    getBreakpointSize: ->
      $visibleDevice = @visibleDevice
      # the page refreshed via turbolinks
      if not $visibleDevice().length
        @setup()
      $visibleDevice = @visibleDevice()
      return $visibleDevice.attr("class").split("visible-")[1]

  @get: ->
    return instance ?= new BreakpointInstance

$ =>
  @bp = Breakpoints.get()
