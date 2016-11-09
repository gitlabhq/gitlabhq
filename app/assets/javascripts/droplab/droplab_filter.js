/* eslint-disable */
(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.filter||(g.filter = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */
droplab.plugin(function init(DropLab) {

  var keydown = function keydown(e) {
    var list = e.detail.hook.list;
    var data = list.data;
    var value = e.detail.hook.trigger.value.toLowerCase();
    var config;
    var matches = [];
    // will only work on dynamically set data
    if(!data){
      return;
    }
    config = droplab.config[e.detail.hook.id];
    matches = data.map(function(o){
      // cheap string search
      o.droplab_hidden = o[config.text].toLowerCase().indexOf(value) === -1;
      return o;
    });
    list.render(matches);
  }

  window.addEventListener('keyup.dl', keydown);
});
},{}]},{},[1])(1)
});
