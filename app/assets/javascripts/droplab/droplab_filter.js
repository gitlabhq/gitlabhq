/* eslint-disable */
(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.filter||(g.filter = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */

require('../window')(function(w){
  w.droplabFilter = {

    keydownWrapper: function(e){
        var hiddenCount = 0;
        var dataHiddenCount = 0;
        var list = e.detail.hook.list;
        var data = list.data;
        var value = e.detail.hook.trigger.value.toLowerCase();
        var config = e.detail.hook.config.droplabFilter;
        var matches = [];
        var filterFunction;
        // will only work on dynamically set data
        if(!data){
          return;
        }

        if (config && config.filterFunction && typeof config.filterFunction === 'function') {
          filterFunction = config.filterFunction;
        } else {
          filterFunction = function(o){
            // cheap string search
            o.droplab_hidden = o[config.template].toLowerCase().indexOf(value) === -1;
            return o;
          };
        }

        dataHiddenCount = data.filter(function(o) {
          return !o.droplab_hidden;
        }).length;

        matches = data.map(function(o) {
          return filterFunction(o, value);
        });

        hiddenCount = matches.filter(function(o) {
          return !o.droplab_hidden;
        }).length;

        if (dataHiddenCount !== hiddenCount) {
          list.render(matches);
          list.currentIndex = 0;
        }
    },

    init: function init(hookInput) {
      var config = hookInput.config.droplabFilter;

      if (!config || (!config.template && !config.filterFunction)) {
        return;
      }

      this.hookInput = hookInput;
      this.hookInput.trigger.addEventListener('keyup.dl', this.keydownWrapper);
    },

    destroy: function destroy(){
      this.hookInput.trigger.removeEventListener('keyup.dl', this.keydownWrapper);
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
