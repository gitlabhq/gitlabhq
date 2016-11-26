(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.remoteFilter||(g.remoteFilter = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */
require('../window')(function(w){
  w.droplabRemoteFilter = {
    timeout: 0,
    nonCharacterKeys: [16, 17, 18, 20, 37, 38, 39, 40, 91, 93],

    init: function init(hook) {
      this.hook = hook;
      this.config = hook.config;

      if (!w.droplabAjax) throw new Error('No droplabAjax plugin found.');
      if (!this.config || !this.config.droplabRemoteFilter.searchKey) {
        throw new Error('Invalid droplabRemoteFilter config.');
      }

      if (!this.config.droplabAjax.params) this.config.droplabAjax.params = {};

      this.bindEvents();

      if (!this.config.droplabAjax.deferRequest) this.debounceTriggerRequest();
    },

    bindEvents: function bindEvents() {
      var trigger = this.hook.trigger;

      trigger.addEventListener('keydown.dl', this.debounceTriggerRequest.bind(this));
      trigger.addEventListener('focus', this.debounceTriggerRequest.bind(this));
      trigger.addEventListener('blur', this.hook.list.hide.bind(this.hook.list));
    },

    unbindEvents: function unbindEvents() {
      var trigger = this.hook.trigger;

      trigger.removeEventListener('keydown.dl', this.debounceTriggerRequest);
      trigger.removeEventListener('focus', this.debounceTriggerRequest);
      trigger.removeEventListener('blur', this.hook.list.hide);
    },

    destroy: function destroy() {
      this.unbindEvents();
    },

    debounceTriggerRequest: function debounceTriggerRequest(e) {
      if (this.isNonCharacterKey(e)) return;

      if (this.timeout) clearTimeout(this.timeout);
      this.timeout = setTimeout(this.triggerRequest.bind(this), 400);
    },

    triggerRequest: function triggerRequest() {
      var searchValue = this.formatValue(this.hook.trigger.value);
      var searchKey = this.config.droplabRemoteFilter.searchKey;
      var params = this.config.droplabAjax.params;

      if (searchValue === params[searchKey]) return this.hook.list.show();
      params[searchKey] = searchValue;

      return w.droplabAjax.load('setData');
    },

    formatValue: function formatValue(value) {
      if (this.config.droplabRemoteFilter.formatValue) {
        return this.config.droplabRemoteFilter.formatValue(value);
      }
      return value;
    },

    isNonCharacterKey: function isNonCharacterKey(e) {
      if (!e) return false;
      var key = e.detail.which || e.detail.keyCode;
      return this.nonCharacterKeys.indexOf(key) > -1;
    },
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
