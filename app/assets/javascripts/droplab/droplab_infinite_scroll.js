(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.infiniteScroll||(g.infiniteScroll = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */
require('../window')(function(w){
  w.droplabInfiniteScroll = {
    timeout: 0,
    isLoading: false,
    nonCharacterKeys: [16, 17, 18, 20, 37, 38, 39, 40, 91, 93],

    init: function init(hook) {
      this.hook = hook;
      this.config = hook.config;

      if (!w.droplabAjax) throw new Error('No droplabAjax plugin found.');
      if (!this.config || !this.config.droplabInfiniteScroll.paginationKey) {
        throw new Error('Invalid droplabInfiniteScroll config.');
      }

      if (!this.config.droplabAjax.params) this.config.droplabAjax.params = {};

      this.bindEvents();
    },

    bindEvents: function bindEvents() {
      var trigger = this.hook.trigger;
      var list = this.hook.list.list;

      list.addEventListener('scroll', this.debounceScroll.bind(this));
      list.addEventListener('mouseenter', this.disableParentScroll);
      list.addEventListener('mouseleave', this.enableParentScroll);
      trigger.addEventListener('keydown.dl', this.reset.bind(this));
      trigger.addEventListener('blur', this.hook.list.hide.bind(this.hook.list));
    },

    unbindEvents: function unbindEvents() {
      var trigger = this.hook.trigger;
      var list = this.hook.list.list;

      list.removeEventListener('scroll', this.debounceScroll);
      list.removeEventListener('mouseenter', this.disableParentScroll);
      list.removeEventListener('mouseleave', this.enableParentScroll);
      trigger.removeEventListener('keydown.dl', this.reset);
      trigger.removeEventListener('blur', this.hook.list.hide);
    },

    destroy: function destroy() {
      this.unbindEvents();
    },

    debounceScroll: function debounceScroll(e) {
      if (this.timeout) clearTimeout(this.timeout);
      if (this.isLoading) return;

      this.timeout = setTimeout(this.loadNextPage.bind(this, e), 400);
    },

    debounceReset: function debounceReset(e) {
      if (this.resetTimeout) clearTimeout(this.resetTimeout);
      this.resetTimeout = setTimeout(this.reset.bind(this, e), 400);
    },

    disableParentScroll: function disableParentScroll() {
      document.body.style.overflow = 'hidden';
      document.documentElement.style.overflow = 'hidden';
    },

    enableParentScroll: function enableParentScroll() {
      document.body.style.overflow = '';
      document.documentElement.style.overflow = '';
    },

    reset: function reset(e) {
      if (this.isNonCharacterKey(e)) return;

      this.config.droplabAjax.params[this.config.droplabInfiniteScroll.paginationKey] = 1;

      this.hook.list.list.scrollTop = 0;
    },

    loadNextPage: function loadNextPage(e) {
      this.isLoading = true;

      var target = e.target;
      var shouldNotLoad = target.scrollTop < target.scrollHeight - target.offsetHeight;

      if (shouldNotLoad) return this.requestCallback();

      var searchValue = this.hook.trigger.value;
      var params = this.config.droplabAjax.params || (this.config.droplabAjax.params = {});
      var paginationKey = this.config.droplabInfiniteScroll.paginationKey || (this.config.droplabInfiniteScroll.paginationKey = {});

      params[paginationKey] = parseInt(params[paginationKey]) + 1 || 1;
      w.droplabAjax.load('addData', this.requestCallback.bind(this));
    },

    requestCallback: function requestCallback(data, req) {
      var params = this.config.droplabAjax.params || (this.config.droplabAjax.params = {});
      var paginationKey = this.config.droplabInfiniteScroll.paginationKey;

      if (data && data.length === 0) params[paginationKey] = parseInt(params[paginationKey]) - 1 || 1;

      this.isLoading = false;
    },

    isNonCharacterKey: function isNonCharacterKey(e) {
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
