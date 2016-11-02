(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.ajax||(g.ajax = {}));g=(g.datasource||(g.datasource = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */
droplab.plugin(function init(DropLab) {
  var _addData = DropLab.prototype.addData;

  var _loadUrlData = function(url) {
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
  };

  Object.assign(DropLab.prototype, {
    addData: function(trigger, data) {
      var _this = this;
      if('string' === typeof data) {
        _loadUrlData(data).then(function(d) {
          _addData.call(_this, trigger, d);
        }).catch(function(e) {
          if(e.message)
            console.error(e.message, e.stack); // eslint-disable-line no-console
          else
            console.error(e); // eslint-disable-line no-console
        })
      } else {
        _addData.apply(this, arguments);
      }
    },
  });
});

},{}]},{},[1])(1)
});