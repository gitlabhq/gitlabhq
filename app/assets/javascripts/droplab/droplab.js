/* eslint-disable */
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

var DropDown = function(list, trigger) {
  this.hidden = true;
  this.list = list;
  this.trigger = trigger;
  this.items = [];
  this.getItems();
  this.addEvents();
};

Object.assign(DropDown.prototype, {
  getItems: function() {
    this.items = [].slice.call(this.list.querySelectorAll('li'));
    return this.items;
  },

  addEvents: function() {
    var self = this;
    // event delegation.
    this.list.addEventListener('click', function(e) {
      if(e.target.tagName === 'A') {
        self.hide();
        var listEvent = new CustomEvent('click.dl', {
          detail: {
            list: self,
            selected: e.target,
            data: e.target.dataset,
          },
        });
        self.list.dispatchEvent(listEvent);
      }
    });
  },

  toggle: function() {
    if(this.hidden) {
      this.show();
    } else {
      this.hide();
    }
  },

  addData: function(data) {
    this.data = (this.data || []).concat(data);
    this.render(data);
  },

  // call render manually on data;
  render: function(data){
    // empty the list first
    var sampleItem;
    var newChildren = [];
    var toAppend;

    this.items.forEach(function(item) {
      sampleItem = item;
      if(item.parentNode && item.parentNode.dataset.hasOwnProperty('dynamic')) {
        item.parentNode.removeChild(item);  
      }
    });

    newChildren = this.data.map(function(dat){
      var html = utils.t(sampleItem.outerHTML, dat);
      var template = document.createElement('template');
      template.innerHTML = html;
      if(dat.hasOwnProperty('droplab_hidden') && dat.droplab_hidden){
        template.content.firstChild.style.display = 'none'
      }else{
        template.content.firstChild.style.display = 'block';
      }
      return template.content.firstChild.outerHTML;
    });
    toAppend = this.list.querySelector('ul[data-dynamic]');
    if(toAppend) {
      toAppend.innerHTML = newChildren.join('');
    } else {
      this.list.innerHTML = newChildren.join('');  
    }
  },

  show: function() {
    this.list.style.display = 'block';
    this.hidden = false;
  },

  hide: function() {
    this.list.style.display = 'none';
    this.hidden = true;
  },
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
      this.plugins = [];
      this.config = {};
      if(typeof hook !== 'undefined'){
        this.addHook(hook);
      }
      this.addEvents();
    };

    Object.assign(DropLab.prototype, {
      plugin: function (plugin) {
        this.plugins.push(plugin)
      },

      addData: function () {
        var args = [].slice.apply(arguments);
        if(this.ready) {
          this._addData.apply(this, args);
        } else {
          this.queuedData = this.queuedData || [];
          this.queuedData.push(args);
        }
      },

      _addData: function(trigger, data) {
        this.hooks.forEach(function(hook) {
          if(hook.trigger.dataset.hasOwnProperty('id')) {
            if(hook.trigger.dataset.id === trigger) {
              hook.list.addData(data);
            }
          }
        });
      },

      addEvents: function() {
        var self = this;
        window.addEventListener('click', function(e){
          var thisTag = e.target;
          if(thisTag.tagName === 'LI' || thisTag.tagName === 'A'){
            // climb up the tree to find the UL
            thisTag = utils.closest(thisTag, 'UL');
          }
          if(utils.isDropDownParts(thisTag)){ return }
          if(utils.isDropDownParts(e.target)){ return }
          self.hooks.forEach(function(hook) {
            hook.list.hide();
          });
        });
      },

      addHook: function(hook) {
        if(!(hook instanceof HTMLElement) && typeof hook === 'string'){
          hook = document.querySelector(hook);
        }
        var list = document.querySelector(hook.dataset[utils.toDataCamelCase(DATA_TRIGGER)]);
        if(hook.tagName === 'A' || hook.tagName === 'BUTTON') {
          this.hooks.push(new HookButton(hook, list));
        } else if(hook.tagName === 'INPUT') {
          this.hooks.push(new HookInput(hook, list));
        }
        return this;
      },

      addHooks: function(hooks) {
        hooks.forEach(this.addHook.bind(this));
        return this;
      },

      setConfig: function(obj){
        this.config = obj;
      },

      init: function () {
        this.plugins.forEach(function(plugin) {
          plugin(DropLab);
        })
        var readyEvent = new CustomEvent('ready.dl', {
          detail: {
            dropdown: this,
          },
        });
        window.dispatchEvent(readyEvent);
        this.ready = true;
        this.queuedData.forEach(function (args) {
          this.addData.apply(this, args);
        }.bind(this));
        this.queuedData = [];
        return this;
      },
    });

    return DropLab;
  };
});

},{"./constants":1,"./custom_event_polyfill":2,"./hook_button":6,"./hook_input":7,"./utils":10,"./window":11}],5:[function(require,module,exports){
var DropDown = require('./dropdown');

var Hook = function(trigger, list){
  this.trigger = trigger;
  this.list = new DropDown(list);
  this.type = 'Hook';
  this.event = 'click';
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

var HookButton = function(trigger, list) {
  Hook.call(this, trigger, list);
  this.type = 'button';
  this.event = 'click';
  this.addEvents();
};

HookButton.prototype = Object.create(Hook.prototype);

Object.assign(HookButton.prototype, {
  addEvents: function(){
    var self = this;
    this.trigger.addEventListener('click', function(e){
      var buttonEvent = new CustomEvent('click.dl', {
        detail: {
          hook: self,
        },
        bubbles: true,
        cancelable: true
      });
      self.list.show();
      e.target.dispatchEvent(buttonEvent);
    });
  },

  constructor: HookButton,
});


module.exports = HookButton;

},{"./custom_event_polyfill":2,"./hook":5}],7:[function(require,module,exports){
var CustomEvent = require('./custom_event_polyfill');
var Hook = require('./hook');

var HookInput = function(trigger, list) {
  Hook.call(this, trigger, list);
  this.type = 'input';
  this.event = 'input';
  this.addEvents();
};

Object.assign(HookInput.prototype, {
  addEvents: function(){
    var self = this;
    this.trigger.addEventListener('mousedown', function(e){
      var mouseEvent = new CustomEvent('mousedown.dl', {
        detail: {
          hook: self,
          text: e.target.value,
        },
        bubbles: true,
        cancelable: true
      });
      e.target.dispatchEvent(mouseEvent);
    });

    this.trigger.addEventListener('input', function(e){
      var inputEvent = new CustomEvent('input.dl', {
        detail: {
          hook: self,
          text: e.target.value,
        },
        bubbles: true,
        cancelable: true
      });
      e.target.dispatchEvent(inputEvent);
      self.list.show();
    });

    this.trigger.addEventListener('keyup', function(e){
      keyEvent(e, 'keyup.dl');
    });

    this.trigger.addEventListener('keydown', function(e){
      keyEvent(e, 'keydown.dl');
    });

    function keyEvent(e, keyEventName){
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
      self.list.show();
    }
  },
});

module.exports = HookInput;

},{"./custom_event_polyfill":2,"./hook":5}],8:[function(require,module,exports){
var DropLab = require('./droplab')();
var DATA_TRIGGER = require('./constants').DATA_TRIGGER;
var keyboard = require('./keyboard')();

var setup = function() {
  var droplab = DropLab();
  require('./window')(function(w) {
    w.addEventListener('load', function() {
      var dropdownTriggers = [].slice.apply(document.querySelectorAll('['+DATA_TRIGGER+']'));
      droplab.addHooks(dropdownTriggers).init();
    });
  });
  return droplab;
};

module.exports = setup();

},{"./constants":1,"./droplab":4,"./keyboard":9,"./window":11}],9:[function(require,module,exports){
require('./window')(function(w){
  module.exports = function(){
    var currentKey;
    var currentFocus;
    var currentIndex = 0;
    var isUpArrow = false;
    var isDownArrow = false;
    var removeHighlight = function removeHighlight(list) {
      var listItems = list.list.querySelectorAll('li');
      listItems.forEach(function(li){
        li.classList.remove('dropdown-active');
      });
      return listItems;
    };

    var setMenuForArrows = function setMenuForArrows(list) {
      var listItems = removeHighlight(list);
      if(currentIndex>0){
        if(!listItems[currentIndex-1]){
          currentIndex = currentIndex-1; 
        }
        listItems[currentIndex-1].classList.add('dropdown-active');
      }
    };

    var mousedown = function mousedown(e) {
      var list = e.detail.hook.list;
      removeHighlight(list);
      list.show();
      currentIndex = 0;
      isUpArrow = false;
      isDownArrow = false;
    };
    var selectItem = function selectItem(list) {
      var listItems = removeHighlight(list);
      var currentItem = listItems[currentIndex-1];
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
  while(thisTag.tagName !== stopTag && thisTag.tagName !== 'HTML'){
    thisTag = thisTag.parentNode;
  }
  return thisTag;
};

var isDropDownParts = function(target) {
  if(target.tagName === 'HTML') { return false; }
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
