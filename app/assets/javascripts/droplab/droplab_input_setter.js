(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.inputSetter||(g.inputSetter = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */

require('../window')(function(w){
  w.droplabInputSetter = {

    init: function init(hookInput) {
      this.config = hookInput.config.droplabInputSetter || (hookInput.config.droplabInputSetter = {});
      this.hookInput = hookInput;
      this.hookInput.list.list.addEventListener('click.dl', this.setInput.bind(this));
    },

    setInput: function setInput(e) {
      var selected = e.detail.selected;
      var textContent = selected.textContent;
      if (!Array.isArray(this.config)) this.config = [this.config];

      this.config.forEach(function(config) {
        var input = config.input || this.hookInput.trigger;

        if (config.valueAttribute) textContent = selected.getAttribute(config.valueAttribute);

        input.value = textContent;
      }.bind(this));
    },

    destroy: function destroy() {
      this.hookInput.list.list.addEventListener('click.dl', this.setInput);
    }
  };
});

},{"../window":2}],2:[function(require,module,exports){
module.exports = function(callback) {
  return (function() {
    callback(this);
  }).call(null);
};

},{}]},{},[1])(1)
});
