/* eslint-disable */
(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.ajax||(g.ajax = {}));g=(g.datasource||(g.datasource = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */

require('../window')(function(w){
  w.droplabAjaxFilter = {
    init: function(hook) {
      this.destroyed = false;
      this.hook = hook;
      this.notLoading();

      this.debounceTriggerWrapper = this.debounceTrigger.bind(this);
      this.hook.trigger.addEventListener('keydown.dl', this.debounceTriggerWrapper);
      this.hook.trigger.addEventListener('focus', this.debounceTriggerWrapper);
      this.trigger(true);
    },

    notLoading: function notLoading() {
      this.loading = false;
    },

    debounceTrigger: function debounceTrigger(e) {
      var NON_CHARACTER_KEYS = [16, 17, 18, 20, 37, 38, 39, 40, 91, 93];
      var invalidKeyPressed = NON_CHARACTER_KEYS.indexOf(e.detail.which || e.detail.keyCode) > -1;
      var focusEvent = e.type === 'focus';

      if (invalidKeyPressed || this.loading) {
        return;
      }

      if (this.timeout) {
        clearTimeout(this.timeout);
      }

      this.timeout = setTimeout(this.trigger.bind(this, focusEvent), 200);
    },

    trigger: function trigger(getEntireList) {
      var config = this.hook.config.droplabAjaxFilter;
      var searchValue = this.trigger.value;

      if (!config || !config.endpoint || !config.searchKey) {
        return;
      }

      if (config.searchValueFunction) {
        searchValue = config.searchValueFunction();
      }

      if (config.loadingTemplate && this.hook.list.data === undefined ||
        this.hook.list.data.length === 0) {
        var dynamicList = this.hook.list.list.querySelector('[data-dynamic]');

        var loadingTemplate = document.createElement('div');
        loadingTemplate.innerHTML = config.loadingTemplate;
        loadingTemplate.setAttribute('data-loading-template', true);

        this.listTemplate = dynamicList.outerHTML;
        dynamicList.outerHTML = loadingTemplate.outerHTML;
      }

      if (getEntireList) {
        searchValue = '';
      }

      if (config.searchKey === searchValue) {
        return this.list.show();
      }

      this.loading = true;

      var params = config.params || {};
      params[config.searchKey] = searchValue;
      var self = this;
      this._loadUrlData(config.endpoint + this.buildParams(params)).then(function(data) {
        if (config.loadingTemplate && self.hook.list.data === undefined ||
          self.hook.list.data.length === 0) {
          const dataLoadingTemplate = self.hook.list.list.querySelector('[data-loading-template]');

          if (dataLoadingTemplate) {
            dataLoadingTemplate.outerHTML = self.listTemplate;
          }
        }

        if (!self.destroyed) {
          var hookListChildren = self.hook.list.list.children;
          var onlyDynamicList = hookListChildren.length === 1 && hookListChildren[0].hasAttribute('data-dynamic');

          if (onlyDynamicList && data.length === 0) {
            self.hook.list.hide();
          }

          self.hook.list.setData.call(self.hook.list, data);
        }
        self.notLoading();
        self.hook.list.currentIndex = 0;
      });
    },

    _loadUrlData: function _loadUrlData(url) {
      return new Promise(function(resolve, reject) {
        var xhr = new XMLHttpRequest;
        xhr.open('GET', url, true);
        xhr.onreadystatechange = function () {
          if(xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
              var data = JSON.parse(xhr.responseText);
              return resolve(data);
            } else {
              return reject([xhr.responseText, xhr.status]);
            }
          }
        };
        xhr.send();
      });
    },

    buildParams: function(params) {
      if (!params) return '';
      var paramsArray = Object.keys(params).map(function(param) {
        return param + '=' + (params[param] || '');
      });
      return '?' + paramsArray.join('&');
    },

    destroy: function destroy() {
      if (this.timeout) {
        clearTimeout(this.timeout);
      }

      this.destroyed = true;

      this.hook.trigger.removeEventListener('keydown.dl', this.debounceTriggerWrapper);
      this.hook.trigger.removeEventListener('focus', this.debounceTriggerWrapper);
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
