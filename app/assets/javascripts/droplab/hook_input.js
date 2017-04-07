/* eslint-disable */

import Hook from './hook';

var HookInput = function(trigger, list, plugins, config) {
  Hook.call(this, trigger, list, plugins, config);

  this.type = 'input';
  this.event = 'input';

  this.eventWrapper = {};

  this.addEvents();
  this.addPlugins();
};

Object.assign(HookInput.prototype, {
  addPlugins: function() {
    this.plugins.forEach(plugin => plugin.init(this));
  },

  addEvents: function(){
    this.eventWrapper.mousedown = this.mousedown.bind(this);
    this.eventWrapper.input = this.input.bind(this);
    this.eventWrapper.keyup = this.keyup.bind(this);
    this.eventWrapper.keydown = this.keydown.bind(this);

    this.trigger.addEventListener('mousedown', this.eventWrapper.mousedown);
    this.trigger.addEventListener('input', this.eventWrapper.input);
    this.trigger.addEventListener('keyup', this.eventWrapper.keyup);
    this.trigger.addEventListener('keydown', this.eventWrapper.keydown);
  },

  removeEvents: function() {
    this.hasRemovedEvents = true;

    this.trigger.removeEventListener('mousedown', this.eventWrapper.mousedown);
    this.trigger.removeEventListener('input', this.eventWrapper.input);
    this.trigger.removeEventListener('keyup', this.eventWrapper.keyup);
    this.trigger.removeEventListener('keydown', this.eventWrapper.keydown);
  },

  input: function(e) {
    if(this.hasRemovedEvents) return;

    this.list.show();

    const inputEvent = new CustomEvent('input.dl', {
      detail: {
        hook: this,
        text: e.target.value,
      },
      bubbles: true,
      cancelable: true
    });
    e.target.dispatchEvent(inputEvent);
  },

  mousedown: function(e) {
    if (this.hasRemovedEvents) return;

    const mouseEvent = new CustomEvent('mousedown.dl', {
      detail: {
        hook: this,
        text: e.target.value,
      },
      bubbles: true,
      cancelable: true,
    });
    e.target.dispatchEvent(mouseEvent);
  },

  keyup: function(e) {
    if (this.hasRemovedEvents) return;

    this.keyEvent(e, 'keyup.dl');
  },

  keydown: function(e) {
    if (this.hasRemovedEvents) return;

    this.keyEvent(e, 'keydown.dl');
  },

  keyEvent: function(e, eventName) {
    this.list.show();

    const keyEvent = new CustomEvent(eventName, {
      detail: {
        hook: this,
        text: e.target.value,
        which: e.which,
        key: e.key,
      },
      bubbles: true,
      cancelable: true,
    });
    e.target.dispatchEvent(keyEvent);
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

    this.list.destroy();
  }
});

export default HookInput;
