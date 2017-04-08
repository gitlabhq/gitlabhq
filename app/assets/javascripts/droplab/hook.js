/* eslint-disable */

import DropDown from './drop_down';

var Hook = function(trigger, list, plugins, config){
  this.trigger = trigger;
  this.list = new DropDown(list);
  this.type = 'Hook';
  this.event = 'click';
  this.plugins = plugins || [];
  this.config = config || {};
  this.id = trigger.id;
};

Object.assign(Hook.prototype, {

  addEvents: function(){},

  constructor: Hook,
});

export default Hook;
