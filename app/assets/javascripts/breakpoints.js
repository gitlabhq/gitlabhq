/* eslint-disable func-names, space-before-function-paren, wrap-iife, one-var, no-var, one-var-declaration-per-line, quotes, no-shadow, prefer-arrow-callback, prefer-template, consistent-return, no-return-assign, new-parens, no-param-reassign, max-len */

var instance, BREAKPOINTS;

instance = null;
BREAKPOINTS = ["xs", "sm", "md", "lg"];

// BreakpointInstance
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
  // Create all the elements
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
  // TODO: Consider refactoring in light of turbolinks removal.
  // the page refreshed via turbolinks
  if (!$visibleDevice().length) {
    this.setup();
  }
  $visibleDevice = this.visibleDevice();
  return $visibleDevice.attr("class").split("visible-")[1];
};

// Breakpoints
function Breakpoints() {}

Breakpoints.get = function() {
  return instance != null ? instance : instance = new BreakpointInstance;
};

$(() => { window.bp = Breakpoints.get(); });

window.Breakpoints = Breakpoints;
