this.Breakpoints = (function() {
  var BreakpointInstance, instance;

  function Breakpoints() {}

  instance = null;

  BreakpointInstance = (function() {
    var BREAKPOINTS;

    BREAKPOINTS = ["xs", "sm", "md", "lg"];

    function BreakpointInstance() {
      this.setup();
    }

    BreakpointInstance.prototype.setup = function() {
      var allDeviceSelector, els;
      allDeviceSelector = BREAKPOINTS.map(function(breakpoint) {
        return ".device-" + breakpoint;
      });
      if ($(allDeviceSelector.join(",")).length) {
        return;
      }
      els = $.map(BREAKPOINTS, function(breakpoint) {
        return "<div class='device-" + breakpoint + " visible-" + breakpoint + "'></div>";
      });
      return $("body").append(els.join(''));
    };

    BreakpointInstance.prototype.visibleDevice = function() {
      var allDeviceSelector;
      allDeviceSelector = BREAKPOINTS.map(function(breakpoint) {
        return ".device-" + breakpoint;
      });
      return $(allDeviceSelector.join(",")).filter(":visible");
    };

    BreakpointInstance.prototype.getBreakpointSize = function() {
      var $visibleDevice;
      $visibleDevice = this.visibleDevice;
      if (!$visibleDevice().length) {
        this.setup();
      }
      $visibleDevice = this.visibleDevice();
      return $visibleDevice.attr("class").split("visible-")[1];
    };

    return BreakpointInstance;

  })();

  Breakpoints.get = function() {
    return instance != null ? instance : instance = new BreakpointInstance;
  };

  return Breakpoints;

})();

$((function(_this) {
  return function() {
    return _this.bp = Breakpoints.get();
  };
})(this));
