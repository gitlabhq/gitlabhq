/* eslint-disable */

import HookButton from './hook_button';
import HookInput from './hook_input';
import utils from './utils';
import Keyboard from './keyboard';
import { DATA_TRIGGER } from './constants';

var DropLab = function() {
  this.ready = false;
  this.hooks = [];
  this.queuedData = [];
  this.config = {};

  this.eventWrapper = {};
};

Object.assign(DropLab.prototype, {
  loadStatic: function(){
    var dropdownTriggers = [].slice.apply(document.querySelectorAll(`[${DATA_TRIGGER}]`));
    this.addHooks(dropdownTriggers);
  },

  addData: function () {
    var args = [].slice.apply(arguments);
    this.applyArgs(args, '_addData');
  },

  setData: function() {
    var args = [].slice.apply(arguments);
    this.applyArgs(args, '_setData');
  },

  destroy: function() {
    this.hooks.forEach(hook => hook.destroy());
    this.hooks = [];
    this.removeEvents();
  },

  applyArgs: function(args, methodName) {
    if (this.ready) return this[methodName].apply(this, args);

    this.queuedData = this.queuedData || [];
    this.queuedData.push(args);
  },

  _addData: function(trigger, data) {
    this._processData(trigger, data, 'addData');
  },

  _setData: function(trigger, data) {
    this._processData(trigger, data, 'setData');
  },

  _processData: function(trigger, data, methodName) {
    this.hooks.forEach((hook) => {
      if (Array.isArray(trigger)) hook.list[methodName](trigger);

      if (hook.trigger.id === trigger) hook.list[methodName](data);
    });
  },

  addEvents: function() {
    this.eventWrapper.documentClicked = this.documentClicked.bind(this)
    document.addEventListener('click', this.eventWrapper.documentClicked);
  },

  documentClicked: function(e) {
    let thisTag = e.target;

    if (thisTag.tagName !== 'UL') thisTag = utils.closest(thisTag, 'UL');
    if (utils.isDropDownParts(thisTag, this.hooks) || utils.isDropDownParts(e.target, this.hooks)) return;

    this.hooks.forEach(hook => hook.list.hide());
  },

  removeEvents: function(){
    document.removeEventListener('click', this.eventWrapper.documentClicked);
  },

  changeHookList: function(trigger, list, plugins, config) {
    const availableTrigger =  typeof trigger === 'string' ? document.getElementById(trigger) : trigger;


    this.hooks.forEach((hook, i) => {
      hook.list.list.dataset.dropdownActive = false;

      if (hook.trigger !== availableTrigger) return;

      hook.destroy();
      this.hooks.splice(i, 1);
      this.addHook(availableTrigger, list, plugins, config);
    });
  },

  addHook: function(hook, list, plugins, config) {
    const availableHook = typeof hook === 'string' ? document.querySelector(hook) : hook;
    let availableList;

    if (typeof list === 'string') {
      availableList = document.querySelector(list);
    } else if (list instanceof Element) {
      availableList = list;
    } else {
      availableList = document.querySelector(hook.dataset[utils.toCamelCase(DATA_TRIGGER)]);
    }

    availableList.dataset.dropdownActive = true;

    const HookObject = availableHook.tagName === 'INPUT' ? HookInput : HookButton;
    this.hooks.push(new HookObject(availableHook, availableList, plugins, config));

    return this;
  },

  addHooks: function(hooks, plugins, config) {
    hooks.forEach(hook => this.addHook(hook, null, plugins, config));
    return this;
  },

  setConfig: function(obj){
    this.config = obj;
  },

  fireReady: function() {
    const readyEvent = new CustomEvent('ready.dl', {
      detail: {
        dropdown: this,
      },
    });
    document.dispatchEvent(readyEvent);

    this.ready = true;
  },

  init: function (hook, list, plugins, config) {
    hook ? this.addHook(hook, list, plugins, config) : this.loadStatic();

    this.addEvents();

    Keyboard();

    this.fireReady();

    this.queuedData.forEach(data => this.addData(data));
    this.queuedData = [];

    return this;
  },
});

export default DropLab;
