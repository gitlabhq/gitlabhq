/* eslint-disable */
(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.ajax||(g.ajax = {}));g=(g.datasource||(g.datasource = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */

require('../window')(function(w){
  function droplabAjaxException(message) {
    this.message = message;
  }

  w.droplabAjax = {
    _loadUrlData: function _loadUrlData(url, params) {
      var paramsUrl = url + params;
      return new Promise((function(resolve, reject) {
        var xhr = new XMLHttpRequest;
        xhr.open('GET', paramsUrl, true);
        xhr.onreadystatechange = (function () {
          if(xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
              var data = JSON.parse(xhr.responseText);
              this.cache[paramsUrl] = data;
              return resolve(data);
            } else {
              return reject([xhr.responseText, xhr.status]);
            }
          }
        }).bind(this);
        xhr.send();
      }).bind(this));
    },

    _loadData: function _loadData(data, methodOverride) {
      if (this.config.loadingTemplate) {
        var dataLoadingTemplate = this.hook.list.list.querySelector('[data-loading-template]');

        if (dataLoadingTemplate) {
          dataLoadingTemplate.outerHTML = this.listTemplate;
        }
      }

      this.hook.list[methodOverride || this.config.method].call(this.hook.list, data);
    },

    init: function init(hook, methodOverride, cb) {
      this.cache = this.cache || {};
      this.hook = hook;
      this.config = hook.config.droplabAjax;

      if ((!this.config || !this.config.endpoint || !this.config.method) ||
      (this.config.method !== 'setData' && this.config.method !== 'addData')) return;

      if (this.config.loadingTemplate) this.initLoadingTemplate();


      if (!this.config.deferRequest) this.load(methodOverride, cb);
    },

    load: function load(methodOverride, cb) {
      var config = this.config.droplabAjax;
      var callback = cb || this.config.callback;
      var params = this.buildParams(this.config.params);
      var cache = this.cache[this.config.endpoint + params];

      if (cache) {
        this._loadData.call(this, cache, methodOverride);
        if (callback) callback();
      } else {
        this._loadUrlData(this.config.endpoint, params)
          .then((function(d) {
            this._loadData.call(this, d, methodOverride);
            if (callback) callback();
          }).bind(this)).catch(function(e) {
            throw new droplabAjaxException(e.message || e);
          });
      }
    },

    initLoadingTemplate: function initLoadingTemplate() {
      var dynamicList = this.hook.list.list.querySelector('[data-loading-template]');

      var loadingTemplate = document.createElement('div');
      loadingTemplate.innerHTML = this.config.loadingTemplate;
      loadingTemplate.setAttribute('data-loading-template', '');

      this.listTemplate = dynamicList.outerHTML;
      dynamicList.outerHTML = loadingTemplate.outerHTML;
    },

    destroy: function() {
      if (this.listTemplate) {
        var dynamicList = this.hook.list.list.querySelector('[data-dynamic]');
        dynamicList.outerHTML = this.listTemplate;
      }
    },

    buildParams: function buildParams(params) {
      if (!params) return '';
      var paramsArray = Object.keys(params).map(function(param) {
        return param + '=' + (params[param] || '');
      });
      return '?' + paramsArray.join('&');
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
