/* eslint-disable */
(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.ajax||(g.ajax = {}));g=(g.datasource||(g.datasource = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */

require('../window')(function(w){
  function droplabAjaxException(message) {
    this.message = message;
  }

  w.droplabAjax = {
    _loadUrlData: function _loadUrlData(url) {
      var self = this;
      return new Promise(function(resolve, reject) {
        var xhr = new XMLHttpRequest;
        xhr.open('GET', url, true);
        xhr.onreadystatechange = function () {
          if(xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
              var data = JSON.parse(xhr.responseText);
              self.cache[url] = data;
              return resolve(data);
            } else {
              return reject([xhr.responseText, xhr.status]);
            }
          }
        };
        xhr.send();
      });
    },

    _loadData: function _loadData(data, config, self) {
      if (config.loadingTemplate) {
        var dataLoadingTemplate = self.hook.list.list.querySelector('[data-loading-template]');

        if (dataLoadingTemplate) {
          dataLoadingTemplate.outerHTML = self.listTemplate;
        }
      }

      self.hook.list[config.method].call(self.hook.list, data);
    },

    init: function init(hook) {
      var self = this;
      self.cache = self.cache || {};
      var config = hook.config.droplabAjax;
      this.hook = hook;

      if (!config || !config.endpoint || !config.method) {
        return;
      }

      if (config.method !== 'setData' && config.method !== 'addData') {
        return;
      }

      if (config.loadingTemplate) {
        var dynamicList = hook.list.list.querySelector('[data-dynamic]');

        var loadingTemplate = document.createElement('div');
        loadingTemplate.innerHTML = config.loadingTemplate;
        loadingTemplate.setAttribute('data-loading-template', '');

        this.listTemplate = dynamicList.outerHTML;
        dynamicList.outerHTML = loadingTemplate.outerHTML;
      }

      if (self.cache[config.endpoint]) {
        self._loadData(self.cache[config.endpoint], config, self);
      } else {
        this._loadUrlData(config.endpoint)
          .then(function(d) {
            self._loadData(d, config, self);
          }).catch(function(e) {
            throw new droplabAjaxException(e.message || e);
          });
      }
    },

    destroy: function() {
      var dynamicList = this.hook.list.list.querySelector('[data-dynamic]');
      if (this.listTemplate && dynamicList) {
        dynamicList.outerHTML = this.listTemplate;
      }
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
