/* eslint-disable */

import Hook from './hook';

var HookButton = function(trigger, list, plugins, config) {
  Hook.call(this, trigger, list, plugins, config);

  this.type = 'button';
  this.event = 'click';

  this.eventWrapper = {};

  this.addEvents();
  this.addPlugins();
};

HookButton.prototype = Object.create(Hook.prototype);

Object.assign(HookButton.prototype, {
  addPlugins: function() {
    this.plugins.forEach(plugin => plugin.init(this));
  },

  clicked: function(e){
    var buttonEvent = new CustomEvent('click.dl', {
      detail: {
        hook: this,
      },
      bubbles: true,
      cancelable: true
    });
    e.target.dispatchEvent(buttonEvent);

    this.list.toggle();
  },

  addEvents: function(){
    this.eventWrapper.clicked = this.clicked.bind(this);
    this.trigger.addEventListener('click', this.eventWrapper.clicked);
  },

  removeEvents: function(){
    this.trigger.removeEventListener('click', this.eventWrapper.clicked);
  },

  restoreInitialState: function() {
    this.list.list.innerHTML = this.list.initialState;
  },

  removePlugins: function() {
    this.plugins.forEach(plugin => plugin.destroy());
  },

  destroy: function() {
    this.restoreInitialState();

    this.removeEvents();
    this.removePlugins();
  },

  constructor: HookButton,
});


export default HookButton;
