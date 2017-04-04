/* eslint-disable */
// Determine where to place this
if (typeof Object.assign != 'function') {
  Object.assign = function (target, varArgs) { // .length of function is 2
    'use strict';
    if (target == null) { // TypeError if undefined or null
      throw new TypeError('Cannot convert undefined or null to object');
    }

    var to = Object(target);

    for (var index = 1; index < arguments.length; index++) {
      var nextSource = arguments[index];

      if (nextSource != null) { // Skip over if undefined or null
        for (var nextKey in nextSource) {
          // Avoid bugs when hasOwnProperty is shadowed
          if (Object.prototype.hasOwnProperty.call(nextSource, nextKey)) {
            to[nextKey] = nextSource[nextKey];
          }
        }
      }
    }
    return to;
  };
}

(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.droplab = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var DATA_TRIGGER = 'data-dropdown-trigger';
var DATA_DROPDOWN = 'data-dropdown';

module.exports = {
  DATA_TRIGGER: DATA_TRIGGER,
  DATA_DROPDOWN: DATA_DROPDOWN,
}

},{}],2:[function(require,module,exports){
// Custom event support for IE
if ( typeof CustomEvent === "function" ) {
  module.exports = CustomEvent;
} else {
  require('./window')(function(w){
    var CustomEvent = function ( event, params ) {
      params = params || { bubbles: false, cancelable: false, detail: undefined };
      var evt = document.createEvent( 'CustomEvent' );
      evt.initCustomEvent( event, params.bubbles, params.cancelable, params.detail );
      return evt;
    }
    CustomEvent.prototype = w.Event.prototype;

    w.CustomEvent = CustomEvent;
  });
  module.exports = CustomEvent;
}

},{"./window":11}],3:[function(require,module,exports){
var CustomEvent = require('./custom_event_polyfill');
var utils = require('./utils');

var DropDown = function(list) {
  this.currentIndex = 0;
  this.hidden = true;
  this.list = list;
  this.items = [];
  this.getItems();
  this.initTemplateString();
  this.addEvents();
  this.initialState = list.innerHTML;
};

Object.assign(DropDown.prototype, {
  getItems: function() {
    this.items = [].slice.call(this.list.querySelectorAll('li'));
    return this.items;
  },

  initTemplateString: function() {
    var items = this.items || this.getItems();

    var templateString = '';
    if(items.length > 0) {
      templateString = items[items.length - 1].outerHTML;
    }
    this.templateString = templateString;
    return this.templateString;
  },

  clickEvent: function(e) {
    // climb up the tree to find the LI
    var selected = utils.closest(e.target, 'LI');

    if(selected) {
      e.preventDefault();
      this.hide();
      var listEvent = new CustomEvent('click.dl', {
        detail: {
          list: this,
          selected: selected,
          data: e.target.dataset,
        },
      });
      this.list.dispatchEvent(listEvent);
    }
  },

  addEvents: function() {
    this.clickWrapper = this.clickEvent.bind(this);
    // event delegation.
    this.list.addEventListener('click', this.clickWrapper);
  },

  toggle: function() {
    if(this.hidden) {
      this.show();
    } else {
      this.hide();
    }
  },

  setData: function(data) {
    this.data = data;
    this.render(data);
  },

  addData: function(data) {
    this.data = (this.data || []).concat(data);
    this.render(this.data);
  },

  // call render manually on data;
  render: function(data){
    // debugger
    // empty the list first
    var templateString = this.templateString;
    var newChildren = [];
    var toAppend;

    newChildren = (data ||[]).map(function(dat){
      var html = utils.t(templateString, dat);
      var template = document.createElement('div');
      template.innerHTML = html;

      // Help set the image src template
      var imageTags = template.querySelectorAll('img[data-src]');
      // debugger
      for(var i = 0; i < imageTags.length; i++) {
        var imageTag = imageTags[i];
        imageTag.src = imageTag.getAttribute('data-src');
        imageTag.removeAttribute('data-src');
      }

      if(dat.hasOwnProperty('droplab_hidden') && dat.droplab_hidden){
        template.firstChild.style.display = 'none'
      }else{
        template.firstChild.style.display = 'block';
      }
      return template.firstChild.outerHTML;
    });
    toAppend = this.list.querySelector('ul[data-dynamic]');
    if(toAppend) {
      toAppend.innerHTML = newChildren.join('');
    } else {
      this.list.innerHTML = newChildren.join('');
    }
  },

  show: function() {
    if (this.hidden) {
      // debugger
      this.list.style.display = 'block';
      this.currentIndex = 0;
      this.hidden = false;
    }
  },

  hide: function() {
    if (!this.hidden) {
      // debugger
      this.list.style.display = 'none';
      this.currentIndex = 0;
      this.hidden = true;
    }
  },

  destroy: function() {
    this.hide();
    this.list.removeEventListener('click', this.clickWrapper);
  }
});

module.exports = DropDown;

},{"./custom_event_polyfill":2,"./utils":10}],4:[function(require,module,exports){
require('./window')(function(w){
  module.exports = function(deps) {
    deps = deps || {};
    var window = deps.window || w;
    var document = deps.document || window.document;
    var CustomEvent = deps.CustomEvent || require('./custom_event_polyfill');
    var HookButton = deps.HookButton || require('./hook_button');
    var HookInput = deps.HookInput || require('./hook_input');
    var utils = deps.utils || require('./utils');
    var DATA_TRIGGER = require('./constants').DATA_TRIGGER;

    var DropLab = function(hook){
      if (!(this instanceof DropLab)) return new DropLab(hook);
      this.ready = false;
      this.hooks = [];
      this.queuedData = [];
      this.config = {};
      this.loadWrapper;
      if(typeof hook !== 'undefined'){
        this.addHook(hook);
      }
    };


    Object.assign(DropLab.prototype, {
      load: function() {
        this.loadWrapper();
      },

      loadWrapper: function(){
        var dropdownTriggers = [].slice.apply(document.querySelectorAll('['+DATA_TRIGGER+']'));
        this.addHooks(dropdownTriggers).init();
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
        for(var i = 0; i < this.hooks.length; i++) {
          this.hooks[i].destroy();
        }
        this.hooks = [];
        this.removeEvents();
      },

      applyArgs: function(args, methodName) {
        if(this.ready) {
          this[methodName].apply(this, args);
        } else {
          this.queuedData = this.queuedData || [];
          this.queuedData.push(args);
        }
      },

      _addData: function(trigger, data) {
        this._processData(trigger, data, 'addData');
      },

      _setData: function(trigger, data) {
        this._processData(trigger, data, 'setData');
      },

      _processData: function(trigger, data, methodName) {
        for(var i = 0; i < this.hooks.length; i++) {
          var hook = this.hooks[i];
          if(hook.trigger.dataset.hasOwnProperty('id')) {
            if(hook.trigger.dataset.id === trigger) {
              hook.list[methodName](data);
            }
          }
        }
      },

      addEvents: function() {
        var self = this;
        this.windowClickedWrapper = function(e){
          var thisTag = e.target;
          if(thisTag.tagName !== 'UL'){
            // climb up the tree to find the UL
            thisTag = utils.closest(thisTag, 'UL');
          }
          if(utils.isDropDownParts(thisTag)){ return }
          if(utils.isDropDownParts(e.target)){ return }
          for(var i = 0; i < self.hooks.length; i++) {
            self.hooks[i].list.hide();
          }
        }.bind(this);
        document.addEventListener('click', this.windowClickedWrapper);
      },

      removeEvents: function(){
        w.removeEventListener('click', this.windowClickedWrapper);
        w.removeEventListener('load', this.loadWrapper);
      },

      changeHookList: function(trigger, list, plugins, config) {
        trigger = document.querySelector('[data-id="'+trigger+'"]');
        // list = document.querySelector(list);
        this.hooks.every(function(hook, i) {
          if(hook.trigger === trigger) {
            hook.destroy();
            this.hooks.splice(i, 1);
            this.addHook(trigger, list, plugins, config);
            return false;
          }
          return true
        }.bind(this));
      },

      addHook: function(hook, list, plugins, config) {
        if(!(hook instanceof HTMLElement) && typeof hook === 'string'){
          hook = document.querySelector(hook);
        }
        if(!list){
          list = document.querySelector(hook.dataset[utils.toDataCamelCase(DATA_TRIGGER)]);
        }

        if(hook) {
          if(hook.tagName === 'A' || hook.tagName === 'BUTTON') {
            this.hooks.push(new HookButton(hook, list, plugins, config));
          } else if(hook.tagName === 'INPUT') {
            this.hooks.push(new HookInput(hook, list, plugins, config));
          }
        }
        return this;
      },

      addHooks: function(hooks, plugins, config) {
        for(var i = 0; i < hooks.length; i++) {
          var hook = hooks[i];
          this.addHook(hook, null, plugins, config);
        }
        return this;
      },

      setConfig: function(obj){
        this.config = obj;
      },

      init: function () {
        this.addEvents();
        var readyEvent = new CustomEvent('ready.dl', {
          detail: {
            dropdown: this,
          },
        });
        window.dispatchEvent(readyEvent);
        this.ready = true;
        for(var i = 0; i < this.queuedData.length; i++) {
          this.addData.apply(this, this.queuedData[i]);
        }
        this.queuedData = [];
        return this;
      },
    });

    return DropLab;
  };
});

},{"./constants":1,"./custom_event_polyfill":2,"./hook_button":6,"./hook_input":7,"./utils":10,"./window":11}],5:[function(require,module,exports){
var DropDown = require('./dropdown');

var Hook = function(trigger, list, plugins, config){
  this.trigger = trigger;
  this.list = new DropDown(list);
  this.type = 'Hook';
  this.event = 'click';
  this.plugins = plugins || [];
  this.config = config || {};
  this.id = trigger.dataset.id;
};

Object.assign(Hook.prototype, {

  addEvents: function(){},

  constructor: Hook,
});

module.exports = Hook;

},{"./dropdown":3}],6:[function(require,module,exports){
var CustomEvent = require('./custom_event_polyfill');
var Hook = require('./hook');

var HookButton = function(trigger, list, plugins, config) {
  Hook.call(this, trigger, list, plugins, config);
  this.type = 'button';
  this.event = 'click';
  this.addEvents();
  this.addPlugins();
};

HookButton.prototype = Object.create(Hook.prototype);

Object.assign(HookButton.prototype, {
  addPlugins: function() {
    for(var i = 0; i < this.plugins.length; i++) {
      this.plugins[i].init(this);
    }
  },

  clicked: function(e){
    var buttonEvent = new CustomEvent('click.dl', {
      detail: {
        hook: this,
      },
      bubbles: true,
      cancelable: true
    });
    this.list.show();
    e.target.dispatchEvent(buttonEvent);
  },

  addEvents: function(){
    this.clickedWrapper = this.clicked.bind(this);
    this.trigger.addEventListener('click', this.clickedWrapper);
  },

  removeEvents: function(){
    this.trigger.removeEventListener('click', this.clickedWrapper);
  },

  restoreInitialState: function() {
    this.list.list.innerHTML = this.list.initialState;
  },

  removePlugins: function() {
    for(var i = 0; i < this.plugins.length; i++) {
      this.plugins[i].destroy();
    }
  },

  destroy: function() {
    this.restoreInitialState();
    this.removeEvents();
    this.removePlugins();
  },


  constructor: HookButton,
});


module.exports = HookButton;

},{"./custom_event_polyfill":2,"./hook":5}],7:[function(require,module,exports){
var CustomEvent = require('./custom_event_polyfill');
var Hook = require('./hook');

var HookInput = function(trigger, list, plugins, config) {
  Hook.call(this, trigger, list, plugins, config);
  this.type = 'input';
  this.event = 'input';
  this.addPlugins();
  this.addEvents();
};

Object.assign(HookInput.prototype, {
  addPlugins: function() {
    var self = this;
    for(var i = 0; i < this.plugins.length; i++) {
      this.plugins[i].init(self);
    }
  },

  addEvents: function(){
    var self = this;

    this.mousedown = function mousedown(e) {
      if(self.hasRemovedEvents) return;

      var mouseEvent = new CustomEvent('mousedown.dl', {
        detail: {
          hook: self,
          text: e.target.value,
        },
        bubbles: true,
        cancelable: true
      });
      e.target.dispatchEvent(mouseEvent);
    }

    this.input = function input(e) {
      if(self.hasRemovedEvents) return;

      self.list.show();

      var inputEvent = new CustomEvent('input.dl', {
        detail: {
          hook: self,
          text: e.target.value,
        },
        bubbles: true,
        cancelable: true
      });
      e.target.dispatchEvent(inputEvent);
    }

    this.keyup = function keyup(e) {
      if(self.hasRemovedEvents) return;

      keyEvent(e, 'keyup.dl');
    }

    this.keydown = function keydown(e) {
      if(self.hasRemovedEvents) return;

      keyEvent(e, 'keydown.dl');
    }

    function keyEvent(e, keyEventName){
      self.list.show();

      var keyEvent = new CustomEvent(keyEventName, {
        detail: {
          hook: self,
          text: e.target.value,
          which: e.which,
          key: e.key,
        },
        bubbles: true,
        cancelable: true
      });
      e.target.dispatchEvent(keyEvent);
    }

    this.events = this.events || {};
    this.events.mousedown = this.mousedown;
    this.events.input = this.input;
    this.events.keyup = this.keyup;
    this.events.keydown = this.keydown;
    this.trigger.addEventListener('mousedown', this.mousedown);
    this.trigger.addEventListener('input', this.input);
    this.trigger.addEventListener('keyup', this.keyup);
    this.trigger.addEventListener('keydown', this.keydown);
  },

  removeEvents: function() {
    this.hasRemovedEvents = true;
    this.trigger.removeEventListener('mousedown', this.mousedown);
    this.trigger.removeEventListener('input', this.input);
    this.trigger.removeEventListener('keyup', this.keyup);
    this.trigger.removeEventListener('keydown', this.keydown);
  },

  restoreInitialState: function() {
    this.list.list.innerHTML = this.list.initialState;
  },

  removePlugins: function() {
    for(var i = 0; i < this.plugins.length; i++) {
      this.plugins[i].destroy();
    }
  },

  destroy: function() {
    this.restoreInitialState();
    this.removeEvents();
    this.removePlugins();
    this.list.destroy();
  }
});

module.exports = HookInput;

},{"./custom_event_polyfill":2,"./hook":5}],8:[function(require,module,exports){
var DropLab = require('./droplab')();
var DATA_TRIGGER = require('./constants').DATA_TRIGGER;
var keyboard = require('./keyboard')();
var setup = function() {
  window.DropLab = DropLab;
};


module.exports = setup();

},{"./constants":1,"./droplab":4,"./keyboard":9}],9:[function(require,module,exports){
require('./window')(function(w){
  module.exports = function(){
    var currentKey;
    var currentFocus;
    var isUpArrow = false;
    var isDownArrow = false;
    var removeHighlight = function removeHighlight(list) {
      var listItems = Array.prototype.slice.call(list.list.querySelectorAll('li:not(.divider)'), 0);
      var listItemsTmp = [];
      for(var i = 0; i < listItems.length; i++) {
        var listItem = listItems[i];
        listItem.classList.remove('dropdown-active');

        if (listItem.style.display !== 'none') {
          listItemsTmp.push(listItem);
        }
      }
      return listItemsTmp;
    };

    var setMenuForArrows = function setMenuForArrows(list) {
      var listItems = removeHighlight(list);
      if(list.currentIndex>0){
        if(!listItems[list.currentIndex-1]){
          list.currentIndex = list.currentIndex-1;
        }

        if (listItems[list.currentIndex-1]) {
          var el = listItems[list.currentIndex-1];
          var filterDropdownEl = el.closest('.filter-dropdown');
          el.classList.add('dropdown-active');

          if (filterDropdownEl) {
            var filterDropdownBottom = filterDropdownEl.offsetHeight;
            var elOffsetTop = el.offsetTop - 30;

            if (elOffsetTop > filterDropdownBottom) {
              filterDropdownEl.scrollTop = elOffsetTop - filterDropdownBottom;
            }
          }
        }
      }
    };

    var mousedown = function mousedown(e) {
      var list = e.detail.hook.list;
      removeHighlight(list);
      list.show();
      list.currentIndex = 0;
      isUpArrow = false;
      isDownArrow = false;
    };
    var selectItem = function selectItem(list) {
      var listItems = removeHighlight(list);
      var currentItem = listItems[list.currentIndex-1];
      var listEvent = new CustomEvent('click.dl', {
        detail: {
          list: list,
          selected: currentItem,
          data: currentItem.dataset,
        },
      });
      list.list.dispatchEvent(listEvent);
      list.hide();
    }

    var keydown = function keydown(e){
      var typedOn = e.target;
      var list = e.detail.hook.list;
      var currentIndex = list.currentIndex;
      isUpArrow = false;
      isDownArrow = false;

      if(e.detail.which){
        currentKey = e.detail.which;
        if(currentKey === 13){
          selectItem(e.detail.hook.list);
          return;
        }
        if(currentKey === 38) {
          isUpArrow = true;
        }
        if(currentKey === 40) {
          isDownArrow = true;
        }
      } else if(e.detail.key) {
        currentKey = e.detail.key;
        if(currentKey === 'Enter'){
          selectItem(e.detail.hook.list);
          return;
        }
        if(currentKey === 'ArrowUp') {
          isUpArrow = true;
        }
        if(currentKey === 'ArrowDown') {
          isDownArrow = true;
        }
      }
      if(isUpArrow){ currentIndex--; }
      if(isDownArrow){ currentIndex++; }
      if(currentIndex < 0){ currentIndex = 0; }
      list.currentIndex = currentIndex;
      setMenuForArrows(e.detail.hook.list);
    };

    w.addEventListener('mousedown.dl', mousedown);
    w.addEventListener('keydown.dl', keydown);
  };
});
},{"./window":11}],10:[function(require,module,exports){
var DATA_TRIGGER = require('./constants').DATA_TRIGGER;
var DATA_DROPDOWN = require('./constants').DATA_DROPDOWN;

var toDataCamelCase = function(attr){
  return this.camelize(attr.split('-').slice(1).join(' '));
};

// the tiniest damn templating I can do
var t = function(s,d){
  for(var p in d)
    s=s.replace(new RegExp('{{'+p+'}}','g'), d[p]);
  return s;
};

var camelize = function(str) {
  return str.replace(/(?:^\w|[A-Z]|\b\w)/g, function(letter, index) {
    return index == 0 ? letter.toLowerCase() : letter.toUpperCase();
  }).replace(/\s+/g, '');
};

var closest = function(thisTag, stopTag) {
  while(thisTag && thisTag.tagName !== stopTag && thisTag.tagName !== 'HTML'){
    thisTag = thisTag.parentNode;
  }
  return thisTag;
};

var isDropDownParts = function(target) {
  if(!target || target.tagName === 'HTML') { return false; }
  return (
    target.hasAttribute(DATA_TRIGGER) ||
      target.hasAttribute(DATA_DROPDOWN)
  );
};

module.exports = {
  toDataCamelCase: toDataCamelCase,
  t: t,
  camelize: camelize,
  closest: closest,
  isDropDownParts: isDropDownParts,
};

},{"./constants":1}],11:[function(require,module,exports){
module.exports = function(callback) {
  return (function() {
    callback(this);
  }).call(null);
};

},{}]},{},[8])(8)
});
