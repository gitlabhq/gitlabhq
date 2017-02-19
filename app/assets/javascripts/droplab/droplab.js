/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// identity function for calling harmony imports with the correct context
/******/ 	__webpack_require__.i = function(value) { return value; };
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, {
/******/ 				configurable: false,
/******/ 				enumerable: true,
/******/ 				get: getter
/******/ 			});
/******/ 		}
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 9);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var DATA_TRIGGER = 'data-dropdown-trigger';
var DATA_DROPDOWN = 'data-dropdown';
var SELECTED_CLASS = 'droplab-item-selected';
var ACTIVE_CLASS = 'droplab-item-active';

var constants = {
  DATA_TRIGGER: DATA_TRIGGER,
  DATA_DROPDOWN: DATA_DROPDOWN,
  SELECTED_CLASS: SELECTED_CLASS,
  ACTIVE_CLASS: ACTIVE_CLASS
};

exports.default = constants;

/***/ }),
/* 1 */
/***/ (function(module, exports) {

// Polyfill for creating CustomEvents on IE9/10/11

// code pulled from:
// https://github.com/d4tocchini/customevent-polyfill
// https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent#Polyfill

try {
    var ce = new window.CustomEvent('test');
    ce.preventDefault();
    if (ce.defaultPrevented !== true) {
        // IE has problems with .preventDefault() on custom events
        // http://stackoverflow.com/questions/23349191
        throw new Error('Could not prevent default');
    }
} catch(e) {
  var CustomEvent = function(event, params) {
    var evt, origPrevent;
    params = params || {
      bubbles: false,
      cancelable: false,
      detail: undefined
    };

    evt = document.createEvent("CustomEvent");
    evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
    origPrevent = evt.preventDefault;
    evt.preventDefault = function () {
      origPrevent.call(this);
      try {
        Object.defineProperty(this, 'defaultPrevented', {
          get: function () {
            return true;
          }
        });
      } catch(e) {
        this.defaultPrevented = true;
      }
    };
    return evt;
  };

  CustomEvent.prototype = window.Event.prototype;
  window.CustomEvent = CustomEvent; // expose definition to window
}


/***/ }),
/* 2 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _dropdown = __webpack_require__(6);

var _dropdown2 = _interopRequireDefault(_dropdown);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Hook = function Hook(trigger, list, plugins, config) {
  this.trigger = trigger;
  this.list = new _dropdown2.default(list);
  this.type = 'Hook';
  this.event = 'click';
  this.plugins = plugins || [];
  this.config = config || {};
  this.id = trigger.id;
};

Object.assign(Hook.prototype, {

  addEvents: function addEvents() {},

  constructor: Hook
});

exports.default = Hook;

/***/ }),
/* 3 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _constants = __webpack_require__(0);

var _constants2 = _interopRequireDefault(_constants);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DATA_TRIGGER = _constants2.default.DATA_TRIGGER,
    DATA_DROPDOWN = _constants2.default.DATA_DROPDOWN;


var utils = {
  toCamelCase: function toCamelCase(attr) {
    return this.camelize(attr.split('-').slice(1).join(' '));
  },
  t: function t(s, d) {
    for (var p in d) {
      if (Object.prototype.hasOwnProperty.call(d, p)) {
        s = s.replace(new RegExp('{{' + p + '}}', 'g'), d[p]);
      }
    }
    return s;
  },
  camelize: function camelize(str) {
    return str.replace(/(?:^\w|[A-Z]|\b\w)/g, function (letter, index) {
      return index === 0 ? letter.toLowerCase() : letter.toUpperCase();
    }).replace(/\s+/g, '');
  },
  closest: function closest(thisTag, stopTag) {
    while (thisTag && thisTag.tagName !== stopTag && thisTag.tagName !== 'HTML') {
      thisTag = thisTag.parentNode;
    }
    return thisTag;
  },
  isDropDownParts: function isDropDownParts(target) {
    if (!target || target.tagName === 'HTML') return false;
    return target.hasAttribute(DATA_TRIGGER) || target.hasAttribute(DATA_DROPDOWN);
  }
};

exports.default = utils;

/***/ }),
/* 4 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function () {
  var DropLab = function DropLab(hook, list) {
    if (!this instanceof DropLab) return new DropLab(hook);

    this.ready = false;
    this.hooks = [];
    this.queuedData = [];
    this.config = {};

    this.eventWrapper = {};

    if (!hook) return this.loadStatic();
    this.addHook(hook, list);
    this.init();
  };

  Object.assign(DropLab.prototype, {
    loadStatic: function loadStatic() {
      var dropdownTriggers = [].slice.apply(document.querySelectorAll('[' + DATA_TRIGGER + ']'));
      this.addHooks(dropdownTriggers).init();
    },

    addData: function addData() {
      var args = [].slice.apply(arguments);
      this.applyArgs(args, '_addData');
    },

    setData: function setData() {
      var args = [].slice.apply(arguments);
      this.applyArgs(args, '_setData');
    },

    destroy: function destroy() {
      this.hooks.forEach(function (hook) {
        return hook.destroy();
      });
      this.hooks = [];
      this.removeEvents();
    },

    applyArgs: function applyArgs(args, methodName) {
      if (this.ready) return this[methodName].apply(this, args);

      this.queuedData = this.queuedData || [];
      this.queuedData.push(args);
    },

    _addData: function _addData(trigger, data) {
      this._processData(trigger, data, 'addData');
    },

    _setData: function _setData(trigger, data) {
      this._processData(trigger, data, 'setData');
    },

    _processData: function _processData(trigger, data, methodName) {
      this.hooks.forEach(function (hook) {
        if (Array.isArray(trigger)) hook.list[methodName](trigger);

        if (hook.trigger.id === trigger) hook.list[methodName](data);
      });
    },

    addEvents: function addEvents() {
      this.eventWrapper.documentClicked = this.documentClicked.bind(this);
      document.addEventListener('click', this.eventWrapper.documentClicked);
    },

    documentClicked: function documentClicked(e) {
      var thisTag = e.target;

      if (thisTag.tagName !== 'UL') thisTag = _utils2.default.closest(thisTag, 'UL');
      if (_utils2.default.isDropDownParts(thisTag, this.hooks) || _utils2.default.isDropDownParts(e.target, this.hooks)) return;

      this.hooks.forEach(function (hook) {
        return hook.list.hide();
      });
    },

    removeEvents: function removeEvents() {
      document.removeEventListener('click', this.eventWrapper.documentClicked);
    },

    changeHookList: function changeHookList(trigger, list, plugins, config) {
      var _this = this;

      var availableTrigger = typeof trigger === 'string' ? document.getElementById(trigger) : trigger;

      this.hooks.forEach(function (hook, i) {
        hook.list.list.dataset.dropdownActive = false;

        if (hook.trigger !== availableTrigger) return;

        hook.destroy();
        _this.hooks.splice(i, 1);
        _this.addHook(availableTrigger, list, plugins, config);
      });
    },

    addHook: function addHook(hook, list, plugins, config) {
      var availableHook = typeof hook === 'string' ? document.querySelector(hook) : hook;
      var availableList = void 0;

      if (typeof list === 'string') {
        availableList = document.querySelector(list);
      } else if (list instanceof Element) {
        availableList = list;
      } else {
        availableList = document.querySelector(hook.dataset[_utils2.default.toCamelCase(DATA_TRIGGER)]);
      }

      availableList.dataset.dropdownActive = true;

      var HookObject = availableHook.tagName === 'INPUT' ? _hook_input2.default : _hook_button2.default;
      this.hooks.push(new HookObject(availableHook, availableList, plugins, config));

      return this;
    },

    addHooks: function addHooks(hooks, plugins, config) {
      var _this2 = this;

      hooks.forEach(function (hook) {
        return _this2.addHook(hook, null, plugins, config);
      });
      return this;
    },

    setConfig: function setConfig(obj) {
      this.config = obj;
    },

    fireReady: function fireReady() {
      var readyEvent = new CustomEvent('ready.dl', {
        detail: {
          dropdown: this
        }
      });
      document.dispatchEvent(readyEvent);

      this.ready = true;
    },

    init: function init() {
      var _this3 = this;

      this.addEvents();

      this.fireReady();

      this.queuedData.forEach(function (data) {
        return _this3.addData(data);
      });
      this.queuedData = [];

      return this;
    }
  });

  return DropLab;
};

__webpack_require__(1);

var _hook_button = __webpack_require__(7);

var _hook_button2 = _interopRequireDefault(_hook_button);

var _hook_input = __webpack_require__(8);

var _hook_input2 = _interopRequireDefault(_hook_input);

var _utils = __webpack_require__(3);

var _utils2 = _interopRequireDefault(_utils);

var _constants = __webpack_require__(0);

var _constants2 = _interopRequireDefault(_constants);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DATA_TRIGGER = _constants2.default.DATA_TRIGGER;

;

/***/ }),
/* 5 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function () {
  var currentKey;
  var currentFocus;
  var isUpArrow = false;
  var isDownArrow = false;
  var removeHighlight = function removeHighlight(list) {
    var itemElements = Array.prototype.slice.call(list.list.querySelectorAll('li:not(.divider)'), 0);
    var listItems = [];
    for (var i = 0; i < itemElements.length; i++) {
      var listItem = itemElements[i];
      listItem.classList.remove(_constants2.default.ACTIVE_CLASS);

      if (listItem.style.display !== 'none') {
        listItems.push(listItem);
      }
    }
    return listItems;
  };

  var setMenuForArrows = function setMenuForArrows(list) {
    var listItems = removeHighlight(list);
    if (list.currentIndex > 0) {
      if (!listItems[list.currentIndex - 1]) {
        list.currentIndex = list.currentIndex - 1;
      }

      if (listItems[list.currentIndex - 1]) {
        var el = listItems[list.currentIndex - 1];
        var filterDropdownEl = el.closest('.filter-dropdown');
        el.classList.add(_constants2.default.ACTIVE_CLASS);

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
    var currentItem = listItems[list.currentIndex - 1];
    var listEvent = new CustomEvent('click.dl', {
      detail: {
        list: list,
        selected: currentItem,
        data: currentItem.dataset
      }
    });
    list.list.dispatchEvent(listEvent);
    list.hide();
  };

  var keydown = function keydown(e) {
    var typedOn = e.target;
    var list = e.detail.hook.list;
    var currentIndex = list.currentIndex;
    isUpArrow = false;
    isDownArrow = false;

    if (e.detail.which) {
      currentKey = e.detail.which;
      if (currentKey === 13) {
        selectItem(e.detail.hook.list);
        return;
      }
      if (currentKey === 38) {
        isUpArrow = true;
      }
      if (currentKey === 40) {
        isDownArrow = true;
      }
    } else if (e.detail.key) {
      currentKey = e.detail.key;
      if (currentKey === 'Enter') {
        selectItem(e.detail.hook.list);
        return;
      }
      if (currentKey === 'ArrowUp') {
        isUpArrow = true;
      }
      if (currentKey === 'ArrowDown') {
        isDownArrow = true;
      }
    }
    if (isUpArrow) {
      currentIndex--;
    }
    if (isDownArrow) {
      currentIndex++;
    }
    if (currentIndex < 0) {
      currentIndex = 0;
    }
    list.currentIndex = currentIndex;
    setMenuForArrows(e.detail.hook.list);
  };

  document.addEventListener('mousedown.dl', mousedown);
  document.addEventListener('keydown.dl', keydown);
};

var _constants = __webpack_require__(0);

var _constants2 = _interopRequireDefault(_constants);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/***/ }),
/* 6 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _Object$assign;

__webpack_require__(1);

var _utils = __webpack_require__(3);

var _utils2 = _interopRequireDefault(_utils);

var _constants = __webpack_require__(0);

var _constants2 = _interopRequireDefault(_constants);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

var DropDown = function DropDown(list) {
  this.currentIndex = 0;
  this.hidden = true;
  this.list = typeof list === 'string' ? document.querySelector(list) : list;
  this.items = [];

  this.eventWrapper = {};

  this.getItems();
  this.initTemplateString();
  this.addEvents();

  this.initialState = list.innerHTML;
};

Object.assign(DropDown.prototype, (_Object$assign = {
  getItems: function getItems() {
    this.items = [].slice.call(this.list.querySelectorAll('li'));
    return this.items;
  },

  initTemplateString: function initTemplateString() {
    var items = this.items || this.getItems();

    var templateString = '';
    if (items.length > 0) templateString = items[items.length - 1].outerHTML;
    this.templateString = templateString;

    return this.templateString;
  },

  clickEvent: function clickEvent(e) {
    var selected = _utils2.default.closest(e.target, 'LI');
    if (!selected) return;

    this.addSelectedClass(selected);

    e.preventDefault();
    this.hide();

    var listEvent = new CustomEvent('click.dl', {
      detail: {
        list: this,
        selected: selected,
        data: e.target.dataset
      }
    });
    this.list.dispatchEvent(listEvent);
  },

  addSelectedClass: function addSelectedClass(selected) {
    this.removeSelectedClasses();
    selected.classList.add(_constants2.default.SELECTED_CLASS);
  },

  removeSelectedClasses: function removeSelectedClasses() {
    var items = this.items || this.getItems();

    items.forEach(function (item) {
      item.classList.remove(_constants2.default.SELECTED_CLASS);
    });
  },

  addEvents: function addEvents() {
    this.eventWrapper.clickEvent = this.clickEvent.bind(this);
    this.list.addEventListener('click', this.eventWrapper.clickEvent);
  },

  toggle: function toggle() {
    this.hidden ? this.show() : this.hide();
  },

  setData: function setData(data) {
    this.data = data;
    this.render(data);
  },

  addData: function addData(data) {
    this.data = (this.data || []).concat(data);
    this.render(this.data);
  },

  render: function render(data) {
    var children = data ? data.map(this.renderChildren.bind(this)) : [];
    var renderableList = this.list.querySelector('ul[data-dynamic]') || this.list;

    renderableList.innerHTML = children.join('');
  },

  renderChildren: function renderChildren(data) {
    var html = _utils2.default.t(this.templateString, data);
    var template = document.createElement('div');

    template.innerHTML = html;
    this.setImagesSrc(template);
    template.firstChild.style.display = data.droplab_hidden ? 'none' : 'block';

    return template.firstChild.outerHTML;
  },

  setImagesSrc: function setImagesSrc(template) {
    var images = [].slice.call(template.querySelectorAll('img[data-src]'));

    images.forEach(function (image) {
      image.src = image.getAttribute('data-src');
      image.removeAttribute('data-src');
    });
  },

  show: function show() {
    if (!this.hidden) return;
    this.list.style.display = 'block';
    this.currentIndex = 0;
    this.hidden = false;
  },

  hide: function hide() {
    if (this.hidden) return;
    this.list.style.display = 'none';
    this.currentIndex = 0;
    this.hidden = true;
  }

}, _defineProperty(_Object$assign, 'toggle', function toggle() {
  this.hidden ? this.show() : this.hide();
}), _defineProperty(_Object$assign, 'destroy', function destroy() {
  this.hide();
  this.list.removeEventListener('click', this.eventWrapper.clickEvent);
}), _Object$assign));

exports.default = DropDown;

/***/ }),
/* 7 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(1);

var _hook = __webpack_require__(2);

var _hook2 = _interopRequireDefault(_hook);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var HookButton = function HookButton(trigger, list, plugins, config) {
  _hook2.default.call(this, trigger, list, plugins, config);

  this.type = 'button';
  this.event = 'click';

  this.eventWrapper = {};

  this.addEvents();
  this.addPlugins();
};

HookButton.prototype = Object.create(_hook2.default.prototype);

Object.assign(HookButton.prototype, {
  addPlugins: function addPlugins() {
    var _this = this;

    this.plugins.forEach(function (plugin) {
      return plugin.init(_this);
    });
  },

  clicked: function clicked(e) {
    var buttonEvent = new CustomEvent('click.dl', {
      detail: {
        hook: this
      },
      bubbles: true,
      cancelable: true
    });
    e.target.dispatchEvent(buttonEvent);

    this.list.toggle();
  },

  addEvents: function addEvents() {
    this.eventWrapper.clicked = this.clicked.bind(this);
    this.trigger.addEventListener('click', this.eventWrapper.clicked);
  },

  removeEvents: function removeEvents() {
    this.trigger.removeEventListener('click', this.eventWrapper.clicked);
  },

  restoreInitialState: function restoreInitialState() {
    this.list.list.innerHTML = this.list.initialState;
  },

  removePlugins: function removePlugins() {
    this.plugins.forEach(function (plugin) {
      return plugin.destroy();
    });
  },

  destroy: function destroy() {
    this.restoreInitialState();

    this.removeEvents();
    this.removePlugins();
  },

  constructor: HookButton
});

exports.default = HookButton;

/***/ }),
/* 8 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(1);

var _hook = __webpack_require__(2);

var _hook2 = _interopRequireDefault(_hook);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var HookInput = function HookInput(trigger, list, plugins, config) {
  _hook2.default.call(this, trigger, list, plugins, config);

  this.type = 'input';
  this.event = 'input';

  this.eventWrapper = {};

  this.addEvents();
  this.addPlugins();
};

Object.assign(HookInput.prototype, {
  addPlugins: function addPlugins() {
    var _this = this;

    this.plugins.forEach(function (plugin) {
      return plugin.init(_this);
    });
  },

  addEvents: function addEvents() {
    this.eventWrapper.mousedown = this.mousedown.bind(this);
    this.eventWrapper.input = this.input.bind(this);
    this.eventWrapper.keyup = this.keyup.bind(this);
    this.eventWrapper.keydown = this.keydown.bind(this);

    this.trigger.addEventListener('mousedown', this.eventWrapper.mousedown);
    this.trigger.addEventListener('input', this.eventWrapper.input);
    this.trigger.addEventListener('keyup', this.eventWrapper.keyup);
    this.trigger.addEventListener('keydown', this.eventWrapper.keydown);
  },

  removeEvents: function removeEvents() {
    this.hasRemovedEvents = true;

    this.trigger.removeEventListener('mousedown', this.eventWrapper.mousedown);
    this.trigger.removeEventListener('input', this.eventWrapper.input);
    this.trigger.removeEventListener('keyup', this.eventWrapper.keyup);
    this.trigger.removeEventListener('keydown', this.eventWrapper.keydown);
  },

  input: function input(e) {
    if (this.hasRemovedEvents) return;

    this.list.show();

    var inputEvent = new CustomEvent('input.dl', {
      detail: {
        hook: this,
        text: e.target.value
      },
      bubbles: true,
      cancelable: true
    });
    e.target.dispatchEvent(inputEvent);
  },

  mousedown: function mousedown(e) {
    if (this.hasRemovedEvents) return;

    var mouseEvent = new CustomEvent('mousedown.dl', {
      detail: {
        hook: this,
        text: e.target.value
      },
      bubbles: true,
      cancelable: true
    });
    e.target.dispatchEvent(mouseEvent);
  },

  keyup: function keyup(e) {
    if (this.hasRemovedEvents) return;

    this.keyEvent(e, 'keyup.dl');
  },

  keydown: function keydown(e) {
    if (this.hasRemovedEvents) return;

    this.keyEvent(e, 'keydown.dl');
  },

  keyEvent: function keyEvent(e, eventName) {
    this.list.show();

    var keyEvent = new CustomEvent(eventName, {
      detail: {
        hook: this,
        text: e.target.value,
        which: e.which,
        key: e.key
      },
      bubbles: true,
      cancelable: true
    });
    e.target.dispatchEvent(keyEvent);
  },

  restoreInitialState: function restoreInitialState() {
    this.list.list.innerHTML = this.list.initialState;
  },

  removePlugins: function removePlugins() {
    this.plugins.forEach(function (plugin) {
      return plugin.destroy();
    });
  },

  destroy: function destroy() {
    this.restoreInitialState();

    this.removeEvents();
    this.removePlugins();

    this.list.destroy();
  }
});

exports.default = HookInput;

/***/ }),
/* 9 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _droplab = __webpack_require__(4);

var _droplab2 = _interopRequireDefault(_droplab);

var _constants = __webpack_require__(0);

var _constants2 = _interopRequireDefault(_constants);

var _keyboard = __webpack_require__(5);

var _keyboard2 = _interopRequireDefault(_keyboard);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DATA_TRIGGER = _constants2.default.DATA_TRIGGER;
var keyboard = (0, _keyboard2.default)();

var setup = function setup() {
  window.DropLab = (0, _droplab2.default)();
};

setup();

exports.default = setup;

/***/ })
/******/ ]);
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAgYTVmZGU1NjJhOGRjY2M3ZTliMTkiLCJ3ZWJwYWNrOi8vLy4vc3JjL2NvbnN0YW50cy5qcyIsIndlYnBhY2s6Ly8vLi9+L2N1c3RvbS1ldmVudC1wb2x5ZmlsbC9jdXN0b20tZXZlbnQtcG9seWZpbGwuanMiLCJ3ZWJwYWNrOi8vLy4vc3JjL2hvb2suanMiLCJ3ZWJwYWNrOi8vLy4vc3JjL3V0aWxzLmpzIiwid2VicGFjazovLy8uL3NyYy9kcm9wbGFiLmpzIiwid2VicGFjazovLy8uL3NyYy9rZXlib2FyZC5qcyIsIndlYnBhY2s6Ly8vLi9zcmMvZHJvcGRvd24uanMiLCJ3ZWJwYWNrOi8vLy4vc3JjL2hvb2tfYnV0dG9uLmpzIiwid2VicGFjazovLy8uL3NyYy9ob29rX2lucHV0LmpzIiwid2VicGFjazovLy8uL3NyYy9pbmRleC5qcyJdLCJuYW1lcyI6WyJEQVRBX1RSSUdHRVIiLCJEQVRBX0RST1BET1dOIiwiU0VMRUNURURfQ0xBU1MiLCJBQ1RJVkVfQ0xBU1MiLCJjb25zdGFudHMiLCJIb29rIiwidHJpZ2dlciIsImxpc3QiLCJwbHVnaW5zIiwiY29uZmlnIiwidHlwZSIsImV2ZW50IiwiaWQiLCJPYmplY3QiLCJhc3NpZ24iLCJwcm90b3R5cGUiLCJhZGRFdmVudHMiLCJjb25zdHJ1Y3RvciIsInV0aWxzIiwidG9DYW1lbENhc2UiLCJhdHRyIiwiY2FtZWxpemUiLCJzcGxpdCIsInNsaWNlIiwiam9pbiIsInQiLCJzIiwiZCIsInAiLCJoYXNPd25Qcm9wZXJ0eSIsImNhbGwiLCJyZXBsYWNlIiwiUmVnRXhwIiwic3RyIiwibGV0dGVyIiwiaW5kZXgiLCJ0b0xvd2VyQ2FzZSIsInRvVXBwZXJDYXNlIiwiY2xvc2VzdCIsInRoaXNUYWciLCJzdG9wVGFnIiwidGFnTmFtZSIsInBhcmVudE5vZGUiLCJpc0Ryb3BEb3duUGFydHMiLCJ0YXJnZXQiLCJoYXNBdHRyaWJ1dGUiLCJEcm9wTGFiIiwiaG9vayIsInJlYWR5IiwiaG9va3MiLCJxdWV1ZWREYXRhIiwiZXZlbnRXcmFwcGVyIiwibG9hZFN0YXRpYyIsImFkZEhvb2siLCJpbml0IiwiZHJvcGRvd25UcmlnZ2VycyIsImFwcGx5IiwiZG9jdW1lbnQiLCJxdWVyeVNlbGVjdG9yQWxsIiwiYWRkSG9va3MiLCJhZGREYXRhIiwiYXJncyIsImFyZ3VtZW50cyIsImFwcGx5QXJncyIsInNldERhdGEiLCJkZXN0cm95IiwiZm9yRWFjaCIsInJlbW92ZUV2ZW50cyIsIm1ldGhvZE5hbWUiLCJwdXNoIiwiX2FkZERhdGEiLCJkYXRhIiwiX3Byb2Nlc3NEYXRhIiwiX3NldERhdGEiLCJBcnJheSIsImlzQXJyYXkiLCJkb2N1bWVudENsaWNrZWQiLCJiaW5kIiwiYWRkRXZlbnRMaXN0ZW5lciIsImUiLCJoaWRlIiwicmVtb3ZlRXZlbnRMaXN0ZW5lciIsImNoYW5nZUhvb2tMaXN0IiwiYXZhaWxhYmxlVHJpZ2dlciIsImdldEVsZW1lbnRCeUlkIiwiaSIsImRhdGFzZXQiLCJkcm9wZG93bkFjdGl2ZSIsInNwbGljZSIsImF2YWlsYWJsZUhvb2siLCJxdWVyeVNlbGVjdG9yIiwiYXZhaWxhYmxlTGlzdCIsIkVsZW1lbnQiLCJIb29rT2JqZWN0Iiwic2V0Q29uZmlnIiwib2JqIiwiZmlyZVJlYWR5IiwicmVhZHlFdmVudCIsIkN1c3RvbUV2ZW50IiwiZGV0YWlsIiwiZHJvcGRvd24iLCJkaXNwYXRjaEV2ZW50IiwiY3VycmVudEtleSIsImN1cnJlbnRGb2N1cyIsImlzVXBBcnJvdyIsImlzRG93bkFycm93IiwicmVtb3ZlSGlnaGxpZ2h0IiwiaXRlbUVsZW1lbnRzIiwibGlzdEl0ZW1zIiwibGVuZ3RoIiwibGlzdEl0ZW0iLCJjbGFzc0xpc3QiLCJyZW1vdmUiLCJzdHlsZSIsImRpc3BsYXkiLCJzZXRNZW51Rm9yQXJyb3dzIiwiY3VycmVudEluZGV4IiwiZWwiLCJmaWx0ZXJEcm9wZG93bkVsIiwiYWRkIiwiZmlsdGVyRHJvcGRvd25Cb3R0b20iLCJvZmZzZXRIZWlnaHQiLCJlbE9mZnNldFRvcCIsIm9mZnNldFRvcCIsInNjcm9sbFRvcCIsIm1vdXNlZG93biIsInNob3ciLCJzZWxlY3RJdGVtIiwiY3VycmVudEl0ZW0iLCJsaXN0RXZlbnQiLCJzZWxlY3RlZCIsImtleWRvd24iLCJ0eXBlZE9uIiwid2hpY2giLCJrZXkiLCJEcm9wRG93biIsImhpZGRlbiIsIml0ZW1zIiwiZ2V0SXRlbXMiLCJpbml0VGVtcGxhdGVTdHJpbmciLCJpbml0aWFsU3RhdGUiLCJpbm5lckhUTUwiLCJ0ZW1wbGF0ZVN0cmluZyIsIm91dGVySFRNTCIsImNsaWNrRXZlbnQiLCJhZGRTZWxlY3RlZENsYXNzIiwicHJldmVudERlZmF1bHQiLCJyZW1vdmVTZWxlY3RlZENsYXNzZXMiLCJpdGVtIiwidG9nZ2xlIiwicmVuZGVyIiwiY29uY2F0IiwiY2hpbGRyZW4iLCJtYXAiLCJyZW5kZXJDaGlsZHJlbiIsInJlbmRlcmFibGVMaXN0IiwiaHRtbCIsInRlbXBsYXRlIiwiY3JlYXRlRWxlbWVudCIsInNldEltYWdlc1NyYyIsImZpcnN0Q2hpbGQiLCJkcm9wbGFiX2hpZGRlbiIsImltYWdlcyIsImltYWdlIiwic3JjIiwiZ2V0QXR0cmlidXRlIiwicmVtb3ZlQXR0cmlidXRlIiwiSG9va0J1dHRvbiIsImFkZFBsdWdpbnMiLCJjcmVhdGUiLCJwbHVnaW4iLCJjbGlja2VkIiwiYnV0dG9uRXZlbnQiLCJidWJibGVzIiwiY2FuY2VsYWJsZSIsInJlc3RvcmVJbml0aWFsU3RhdGUiLCJyZW1vdmVQbHVnaW5zIiwiSG9va0lucHV0IiwiaW5wdXQiLCJrZXl1cCIsImhhc1JlbW92ZWRFdmVudHMiLCJpbnB1dEV2ZW50IiwidGV4dCIsInZhbHVlIiwibW91c2VFdmVudCIsImtleUV2ZW50IiwiZXZlbnROYW1lIiwia2V5Ym9hcmQiLCJzZXR1cCIsIndpbmRvdyJdLCJtYXBwaW5ncyI6IjtBQUFBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7QUFD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QUlOQyxhQUFLdkQsRUFBRXVEO0FBSkQsT0FEa0M7QUFPMUN1QyxlQUFTLElBUGlDO0FBUTFDQyxrQkFBWTtBQVI4QixLQUEzQixDQUFqQjtBQVVBL0YsTUFBRW5DLE1BQUYsQ0FBU3lELGFBQVQsQ0FBdUJvRixRQUF2QjtBQUNELEdBbEZnQzs7QUFvRmpDVix1QkFBcUIsK0JBQVc7QUFDOUIsU0FBS3hLLElBQUwsQ0FBVUEsSUFBVixDQUFlc0ksU0FBZixHQUEyQixLQUFLdEksSUFBTCxDQUFVcUksWUFBckM7QUFDRCxHQXRGZ0M7O0FBd0ZqQ29DLGlCQUFlLHlCQUFXO0FBQ3hCLFNBQUt4SyxPQUFMLENBQWEwRCxPQUFiLENBQXFCO0FBQUEsYUFBVXdHLE9BQU96RyxPQUFQLEVBQVY7QUFBQSxLQUFyQjtBQUNELEdBMUZnQzs7QUE0RmpDQSxXQUFTLG1CQUFXO0FBQ2xCLFNBQUs4RyxtQkFBTDs7QUFFQSxTQUFLNUcsWUFBTDtBQUNBLFNBQUs2RyxhQUFMOztBQUVBLFNBQUt6SyxJQUFMLENBQVUwRCxPQUFWO0FBQ0Q7QUFuR2dDLENBQW5DOztrQkFzR2VnSCxTOzs7Ozs7Ozs7Ozs7O0FDckhmOzs7O0FBQ0E7Ozs7QUFDQTs7Ozs7O0FBRUEsSUFBTWpMLGVBQWUsb0JBQVVBLFlBQS9CO0FBQ0EsSUFBTTJMLFdBQVcseUJBQWpCOztBQUVBLElBQU1DLFFBQVEsU0FBUkEsS0FBUSxHQUFZO0FBQ3hCQyxTQUFPL0ksT0FBUCxHQUFpQix3QkFBakI7QUFDRCxDQUZEOztBQUlBOEk7O2tCQUVlQSxLIiwiZmlsZSI6Ii4vZGlzdC9kcm9wbGFiLmpzIiwic291cmNlc0NvbnRlbnQiOlsiIFx0Ly8gVGhlIG1vZHVsZSBjYWNoZVxuIFx0dmFyIGluc3RhbGxlZE1vZHVsZXMgPSB7fTtcblxuIFx0Ly8gVGhlIHJlcXVpcmUgZnVuY3Rpb25cbiBcdGZ1bmN0aW9uIF9fd2VicGFja19yZXF1aXJlX18obW9kdWxlSWQpIHtcblxuIFx0XHQvLyBDaGVjayBpZiBtb2R1bGUgaXMgaW4gY2FjaGVcbiBcdFx0aWYoaW5zdGFsbGVkTW9kdWxlc1ttb2R1bGVJZF0pXG4gXHRcdFx0cmV0dXJuIGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdLmV4cG9ydHM7XG5cbiBcdFx0Ly8gQ3JlYXRlIGEgbmV3IG1vZHVsZSAoYW5kIHB1dCBpdCBpbnRvIHRoZSBjYWNoZSlcbiBcdFx0dmFyIG1vZHVsZSA9IGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdID0ge1xuIFx0XHRcdGk6IG1vZHVsZUlkLFxuIFx0XHRcdGw6IGZhbHNlLFxuIFx0XHRcdGV4cG9ydHM6IHt9XG4gXHRcdH07XG5cbiBcdFx0Ly8gRXhlY3V0ZSB0aGUgbW9kdWxlIGZ1bmN0aW9uXG4gXHRcdG1vZHVsZXNbbW9kdWxlSWRdLmNhbGwobW9kdWxlLmV4cG9ydHMsIG1vZHVsZSwgbW9kdWxlLmV4cG9ydHMsIF9fd2VicGFja19yZXF1aXJlX18pO1xuXG4gXHRcdC8vIEZsYWcgdGhlIG1vZHVsZSBhcyBsb2FkZWRcbiBcdFx0bW9kdWxlLmwgPSB0cnVlO1xuXG4gXHRcdC8vIFJldHVybiB0aGUgZXhwb3J0cyBvZiB0aGUgbW9kdWxlXG4gXHRcdHJldHVybiBtb2R1bGUuZXhwb3J0cztcbiBcdH1cblxuXG4gXHQvLyBleHBvc2UgdGhlIG1vZHVsZXMgb2JqZWN0IChfX3dlYnBhY2tfbW9kdWxlc19fKVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5tID0gbW9kdWxlcztcblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGUgY2FjaGVcbiBcdF9fd2VicGFja19yZXF1aXJlX18uYyA9IGluc3RhbGxlZE1vZHVsZXM7XG5cbiBcdC8vIGlkZW50aXR5IGZ1bmN0aW9uIGZvciBjYWxsaW5nIGhhcm1vbnkgaW1wb3J0cyB3aXRoIHRoZSBjb3JyZWN0IGNvbnRleHRcbiBcdF9fd2VicGFja19yZXF1aXJlX18uaSA9IGZ1bmN0aW9uKHZhbHVlKSB7IHJldHVybiB2YWx1ZTsgfTtcblxuIFx0Ly8gZGVmaW5lIGdldHRlciBmdW5jdGlvbiBmb3IgaGFybW9ueSBleHBvcnRzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQgPSBmdW5jdGlvbihleHBvcnRzLCBuYW1lLCBnZXR0ZXIpIHtcbiBcdFx0aWYoIV9fd2VicGFja19yZXF1aXJlX18ubyhleHBvcnRzLCBuYW1lKSkge1xuIFx0XHRcdE9iamVjdC5kZWZpbmVQcm9wZXJ0eShleHBvcnRzLCBuYW1lLCB7XG4gXHRcdFx0XHRjb25maWd1cmFibGU6IGZhbHNlLFxuIFx0XHRcdFx0ZW51bWVyYWJsZTogdHJ1ZSxcbiBcdFx0XHRcdGdldDogZ2V0dGVyXG4gXHRcdFx0fSk7XG4gXHRcdH1cbiBcdH07XG5cbiBcdC8vIGdldERlZmF1bHRFeHBvcnQgZnVuY3Rpb24gZm9yIGNvbXBhdGliaWxpdHkgd2l0aCBub24taGFybW9ueSBtb2R1bGVzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm4gPSBmdW5jdGlvbihtb2R1bGUpIHtcbiBcdFx0dmFyIGdldHRlciA9IG1vZHVsZSAmJiBtb2R1bGUuX19lc01vZHVsZSA/XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0RGVmYXVsdCgpIHsgcmV0dXJuIG1vZHVsZVsnZGVmYXVsdCddOyB9IDpcbiBcdFx0XHRmdW5jdGlvbiBnZXRNb2R1bGVFeHBvcnRzKCkgeyByZXR1cm4gbW9kdWxlOyB9O1xuIFx0XHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQoZ2V0dGVyLCAnYScsIGdldHRlcik7XG4gXHRcdHJldHVybiBnZXR0ZXI7XG4gXHR9O1xuXG4gXHQvLyBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGxcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubyA9IGZ1bmN0aW9uKG9iamVjdCwgcHJvcGVydHkpIHsgcmV0dXJuIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbChvYmplY3QsIHByb3BlcnR5KTsgfTtcblxuIFx0Ly8gX193ZWJwYWNrX3B1YmxpY19wYXRoX19cbiBcdF9fd2VicGFja19yZXF1aXJlX18ucCA9IFwiXCI7XG5cbiBcdC8vIExvYWQgZW50cnkgbW9kdWxlIGFuZCByZXR1cm4gZXhwb3J0c1xuIFx0cmV0dXJuIF9fd2VicGFja19yZXF1aXJlX18oX193ZWJwYWNrX3JlcXVpcmVfXy5zID0gOSk7XG5cblxuXG4vLyBXRUJQQUNLIEZPT1RFUiAvL1xuLy8gd2VicGFjay9ib290c3RyYXAgYTVmZGU1NjJhOGRjY2M3ZTliMTkiLCJjb25zdCBEQVRBX1RSSUdHRVIgPSAnZGF0YS1kcm9wZG93bi10cmlnZ2VyJztcbmNvbnN0IERBVEFfRFJPUERPV04gPSAnZGF0YS1kcm9wZG93bic7XG5jb25zdCBTRUxFQ1RFRF9DTEFTUyA9ICdkcm9wbGFiLWl0ZW0tc2VsZWN0ZWQnO1xuY29uc3QgQUNUSVZFX0NMQVNTID0gJ2Ryb3BsYWItaXRlbS1hY3RpdmUnO1xuXG5jb25zdCBjb25zdGFudHMgPSB7XG4gIERBVEFfVFJJR0dFUixcbiAgREFUQV9EUk9QRE9XTixcbiAgU0VMRUNURURfQ0xBU1MsXG4gIEFDVElWRV9DTEFTUyxcbn07XG5cbmV4cG9ydCBkZWZhdWx0IGNvbnN0YW50cztcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyAuL3NyYy9jb25zdGFudHMuanMiLCIvLyBQb2x5ZmlsbCBmb3IgY3JlYXRpbmcgQ3VzdG9tRXZlbnRzIG9uIElFOS8xMC8xMVxuXG4vLyBjb2RlIHB1bGxlZCBmcm9tOlxuLy8gaHR0cHM6Ly9naXRodWIuY29tL2Q0dG9jY2hpbmkvY3VzdG9tZXZlbnQtcG9seWZpbGxcbi8vIGh0dHBzOi8vZGV2ZWxvcGVyLm1vemlsbGEub3JnL2VuLVVTL2RvY3MvV2ViL0FQSS9DdXN0b21FdmVudCNQb2x5ZmlsbFxuXG50cnkge1xuICAgIHZhciBjZSA9IG5ldyB3aW5kb3cuQ3VzdG9tRXZlbnQoJ3Rlc3QnKTtcbiAgICBjZS5wcmV2ZW50RGVmYXVsdCgpO1xuICAgIGlmIChjZS5kZWZhdWx0UHJldmVudGVkICE9PSB0cnVlKSB7XG4gICAgICAgIC8vIElFIGhhcyBwcm9ibGVtcyB3aXRoIC5wcmV2ZW50RGVmYXVsdCgpIG9uIGN1c3RvbSBldmVudHNcbiAgICAgICAgLy8gaHR0cDovL3N0YWNrb3ZlcmZsb3cuY29tL3F1ZXN0aW9ucy8yMzM0OTE5MVxuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoJ0NvdWxkIG5vdCBwcmV2ZW50IGRlZmF1bHQnKTtcbiAgICB9XG59IGNhdGNoKGUpIHtcbiAgdmFyIEN1c3RvbUV2ZW50ID0gZnVuY3Rpb24oZXZlbnQsIHBhcmFtcykge1xuICAgIHZhciBldnQsIG9yaWdQcmV2ZW50O1xuICAgIHBhcmFtcyA9IHBhcmFtcyB8fCB7XG4gICAgICBidWJibGVzOiBmYWxzZSxcbiAgICAgIGNhbmNlbGFibGU6IGZhbHNlLFxuICAgICAgZGV0YWlsOiB1bmRlZmluZWRcbiAgICB9O1xuXG4gICAgZXZ0ID0gZG9jdW1lbnQuY3JlYXRlRXZlbnQoXCJDdXN0b21FdmVudFwiKTtcbiAgICBldnQuaW5pdEN1c3RvbUV2ZW50KGV2ZW50LCBwYXJhbXMuYnViYmxlcywgcGFyYW1zLmNhbmNlbGFibGUsIHBhcmFtcy5kZXRhaWwpO1xuICAgIG9yaWdQcmV2ZW50ID0gZXZ0LnByZXZlbnREZWZhdWx0O1xuICAgIGV2dC5wcmV2ZW50RGVmYXVsdCA9IGZ1bmN0aW9uICgpIHtcbiAgICAgIG9yaWdQcmV2ZW50LmNhbGwodGhpcyk7XG4gICAgICB0cnkge1xuICAgICAgICBPYmplY3QuZGVmaW5lUHJvcGVydHkodGhpcywgJ2RlZmF1bHRQcmV2ZW50ZWQnLCB7XG4gICAgICAgICAgZ2V0OiBmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgICAgICB9XG4gICAgICAgIH0pO1xuICAgICAgfSBjYXRjaChlKSB7XG4gICAgICAgIHRoaXMuZGVmYXVsdFByZXZlbnRlZCA9IHRydWU7XG4gICAgICB9XG4gICAgfTtcbiAgICByZXR1cm4gZXZ0O1xuICB9O1xuXG4gIEN1c3RvbUV2ZW50LnByb3RvdHlwZSA9IHdpbmRvdy5FdmVudC5wcm90b3R5cGU7XG4gIHdpbmRvdy5DdXN0b21FdmVudCA9IEN1c3RvbUV2ZW50OyAvLyBleHBvc2UgZGVmaW5pdGlvbiB0byB3aW5kb3dcbn1cblxuXG5cbi8vLy8vLy8vLy8vLy8vLy8vL1xuLy8gV0VCUEFDSyBGT09URVJcbi8vIC4vfi9jdXN0b20tZXZlbnQtcG9seWZpbGwvY3VzdG9tLWV2ZW50LXBvbHlmaWxsLmpzXG4vLyBtb2R1bGUgaWQgPSAxXG4vLyBtb2R1bGUgY2h1bmtzID0gMCIsImltcG9ydCBEcm9wRG93biBmcm9tICcuL2Ryb3Bkb3duJztcblxudmFyIEhvb2sgPSBmdW5jdGlvbih0cmlnZ2VyLCBsaXN0LCBwbHVnaW5zLCBjb25maWcpe1xuICB0aGlzLnRyaWdnZXIgPSB0cmlnZ2VyO1xuICB0aGlzLmxpc3QgPSBuZXcgRHJvcERvd24obGlzdCk7XG4gIHRoaXMudHlwZSA9ICdIb29rJztcbiAgdGhpcy5ldmVudCA9ICdjbGljayc7XG4gIHRoaXMucGx1Z2lucyA9IHBsdWdpbnMgfHwgW107XG4gIHRoaXMuY29uZmlnID0gY29uZmlnIHx8IHt9O1xuICB0aGlzLmlkID0gdHJpZ2dlci5pZDtcbn07XG5cbk9iamVjdC5hc3NpZ24oSG9vay5wcm90b3R5cGUsIHtcblxuICBhZGRFdmVudHM6IGZ1bmN0aW9uKCl7fSxcblxuICBjb25zdHJ1Y3RvcjogSG9vayxcbn0pO1xuXG5leHBvcnQgZGVmYXVsdCBIb29rO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL2hvb2suanMiLCJpbXBvcnQgY29uc3RhbnRzIGZyb20gJy4vY29uc3RhbnRzJztcblxuY29uc3QgeyBEQVRBX1RSSUdHRVIsIERBVEFfRFJPUERPV04gfSA9IGNvbnN0YW50cztcblxuY29uc3QgdXRpbHMgPSB7XG4gIHRvQ2FtZWxDYXNlKGF0dHIpIHtcbiAgICByZXR1cm4gdGhpcy5jYW1lbGl6ZShhdHRyLnNwbGl0KCctJykuc2xpY2UoMSkuam9pbignICcpKTtcbiAgfSxcblxuICB0KHMsIGQpIHtcbiAgICBmb3IgKGNvbnN0IHAgaW4gZCkge1xuICAgICAgaWYgKE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbChkLCBwKSkge1xuICAgICAgICBzID0gcy5yZXBsYWNlKG5ldyBSZWdFeHAoYHt7JHtwfX19YCwgJ2cnKSwgZFtwXSk7XG4gICAgICB9XG4gICAgfVxuICAgIHJldHVybiBzO1xuICB9LFxuXG4gIGNhbWVsaXplKHN0cikge1xuICAgIHJldHVybiBzdHIucmVwbGFjZSgvKD86Xlxcd3xbQS1aXXxcXGJcXHcpL2csIChsZXR0ZXIsIGluZGV4KSA9PiB7XG4gICAgICByZXR1cm4gaW5kZXggPT09IDAgPyBsZXR0ZXIudG9Mb3dlckNhc2UoKSA6IGxldHRlci50b1VwcGVyQ2FzZSgpO1xuICAgIH0pLnJlcGxhY2UoL1xccysvZywgJycpO1xuICB9LFxuXG4gIGNsb3Nlc3QodGhpc1RhZywgc3RvcFRhZykge1xuICAgIHdoaWxlICh0aGlzVGFnICYmIHRoaXNUYWcudGFnTmFtZSAhPT0gc3RvcFRhZyAmJiB0aGlzVGFnLnRhZ05hbWUgIT09ICdIVE1MJykge1xuICAgICAgdGhpc1RhZyA9IHRoaXNUYWcucGFyZW50Tm9kZTtcbiAgICB9XG4gICAgcmV0dXJuIHRoaXNUYWc7XG4gIH0sXG5cbiAgaXNEcm9wRG93blBhcnRzKHRhcmdldCkge1xuICAgIGlmICghdGFyZ2V0IHx8IHRhcmdldC50YWdOYW1lID09PSAnSFRNTCcpIHJldHVybiBmYWxzZTtcbiAgICByZXR1cm4gdGFyZ2V0Lmhhc0F0dHJpYnV0ZShEQVRBX1RSSUdHRVIpIHx8IHRhcmdldC5oYXNBdHRyaWJ1dGUoREFUQV9EUk9QRE9XTik7XG4gIH0sXG59O1xuXG5cbmV4cG9ydCBkZWZhdWx0IHV0aWxzO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL3V0aWxzLmpzIiwiaW1wb3J0ICdjdXN0b20tZXZlbnQtcG9seWZpbGwnO1xuaW1wb3J0IEhvb2tCdXR0b24gZnJvbSAnLi9ob29rX2J1dHRvbic7XG5pbXBvcnQgSG9va0lucHV0IGZyb20gJy4vaG9va19pbnB1dCc7XG5pbXBvcnQgdXRpbHMgZnJvbSAnLi91dGlscyc7XG5pbXBvcnQgY29uc3RhbnRzIGZyb20gJy4vY29uc3RhbnRzJztcbmNvbnN0IERBVEFfVFJJR0dFUiA9IGNvbnN0YW50cy5EQVRBX1RSSUdHRVI7XG5cbmV4cG9ydCBkZWZhdWx0IGZ1bmN0aW9uICgpIHtcbiAgdmFyIERyb3BMYWIgPSBmdW5jdGlvbihob29rLCBsaXN0KSB7XG4gICAgaWYgKCF0aGlzIGluc3RhbmNlb2YgRHJvcExhYikgcmV0dXJuIG5ldyBEcm9wTGFiKGhvb2spO1xuXG4gICAgdGhpcy5yZWFkeSA9IGZhbHNlO1xuICAgIHRoaXMuaG9va3MgPSBbXTtcbiAgICB0aGlzLnF1ZXVlZERhdGEgPSBbXTtcbiAgICB0aGlzLmNvbmZpZyA9IHt9O1xuXG4gICAgdGhpcy5ldmVudFdyYXBwZXIgPSB7fTtcblxuICAgIGlmICghaG9vaykgcmV0dXJuIHRoaXMubG9hZFN0YXRpYygpO1xuICAgIHRoaXMuYWRkSG9vayhob29rLCBsaXN0KTtcbiAgICB0aGlzLmluaXQoKTtcbiAgfTtcblxuICBPYmplY3QuYXNzaWduKERyb3BMYWIucHJvdG90eXBlLCB7XG4gICAgbG9hZFN0YXRpYzogZnVuY3Rpb24oKXtcbiAgICAgIHZhciBkcm9wZG93blRyaWdnZXJzID0gW10uc2xpY2UuYXBwbHkoZG9jdW1lbnQucXVlcnlTZWxlY3RvckFsbChgWyR7REFUQV9UUklHR0VSfV1gKSk7XG4gICAgICB0aGlzLmFkZEhvb2tzKGRyb3Bkb3duVHJpZ2dlcnMpLmluaXQoKTtcbiAgICB9LFxuXG4gICAgYWRkRGF0YTogZnVuY3Rpb24gKCkge1xuICAgICAgdmFyIGFyZ3MgPSBbXS5zbGljZS5hcHBseShhcmd1bWVudHMpO1xuICAgICAgdGhpcy5hcHBseUFyZ3MoYXJncywgJ19hZGREYXRhJyk7XG4gICAgfSxcblxuICAgIHNldERhdGE6IGZ1bmN0aW9uKCkge1xuICAgICAgdmFyIGFyZ3MgPSBbXS5zbGljZS5hcHBseShhcmd1bWVudHMpO1xuICAgICAgdGhpcy5hcHBseUFyZ3MoYXJncywgJ19zZXREYXRhJyk7XG4gICAgfSxcblxuICAgIGRlc3Ryb3k6IGZ1bmN0aW9uKCkge1xuICAgICAgdGhpcy5ob29rcy5mb3JFYWNoKGhvb2sgPT4gaG9vay5kZXN0cm95KCkpO1xuICAgICAgdGhpcy5ob29rcyA9IFtdO1xuICAgICAgdGhpcy5yZW1vdmVFdmVudHMoKTtcbiAgICB9LFxuXG4gICAgYXBwbHlBcmdzOiBmdW5jdGlvbihhcmdzLCBtZXRob2ROYW1lKSB7XG4gICAgICBpZiAodGhpcy5yZWFkeSkgcmV0dXJuIHRoaXNbbWV0aG9kTmFtZV0uYXBwbHkodGhpcywgYXJncyk7XG5cbiAgICAgIHRoaXMucXVldWVkRGF0YSA9IHRoaXMucXVldWVkRGF0YSB8fCBbXTtcbiAgICAgIHRoaXMucXVldWVkRGF0YS5wdXNoKGFyZ3MpO1xuICAgIH0sXG5cbiAgICBfYWRkRGF0YTogZnVuY3Rpb24odHJpZ2dlciwgZGF0YSkge1xuICAgICAgdGhpcy5fcHJvY2Vzc0RhdGEodHJpZ2dlciwgZGF0YSwgJ2FkZERhdGEnKTtcbiAgICB9LFxuXG4gICAgX3NldERhdGE6IGZ1bmN0aW9uKHRyaWdnZXIsIGRhdGEpIHtcbiAgICAgIHRoaXMuX3Byb2Nlc3NEYXRhKHRyaWdnZXIsIGRhdGEsICdzZXREYXRhJyk7XG4gICAgfSxcblxuICAgIF9wcm9jZXNzRGF0YTogZnVuY3Rpb24odHJpZ2dlciwgZGF0YSwgbWV0aG9kTmFtZSkge1xuICAgICAgdGhpcy5ob29rcy5mb3JFYWNoKChob29rKSA9PiB7XG4gICAgICAgIGlmIChBcnJheS5pc0FycmF5KHRyaWdnZXIpKSBob29rLmxpc3RbbWV0aG9kTmFtZV0odHJpZ2dlcik7XG5cbiAgICAgICAgaWYgKGhvb2sudHJpZ2dlci5pZCA9PT0gdHJpZ2dlcikgaG9vay5saXN0W21ldGhvZE5hbWVdKGRhdGEpO1xuICAgICAgfSk7XG4gICAgfSxcblxuICAgIGFkZEV2ZW50czogZnVuY3Rpb24oKSB7XG4gICAgICB0aGlzLmV2ZW50V3JhcHBlci5kb2N1bWVudENsaWNrZWQgPSB0aGlzLmRvY3VtZW50Q2xpY2tlZC5iaW5kKHRoaXMpXG4gICAgICBkb2N1bWVudC5hZGRFdmVudExpc3RlbmVyKCdjbGljaycsIHRoaXMuZXZlbnRXcmFwcGVyLmRvY3VtZW50Q2xpY2tlZCk7XG4gICAgfSxcblxuICAgIGRvY3VtZW50Q2xpY2tlZDogZnVuY3Rpb24oZSkge1xuICAgICAgbGV0IHRoaXNUYWcgPSBlLnRhcmdldDtcblxuICAgICAgaWYgKHRoaXNUYWcudGFnTmFtZSAhPT0gJ1VMJykgdGhpc1RhZyA9IHV0aWxzLmNsb3Nlc3QodGhpc1RhZywgJ1VMJyk7XG4gICAgICBpZiAodXRpbHMuaXNEcm9wRG93blBhcnRzKHRoaXNUYWcsIHRoaXMuaG9va3MpIHx8IHV0aWxzLmlzRHJvcERvd25QYXJ0cyhlLnRhcmdldCwgdGhpcy5ob29rcykpIHJldHVybjtcblxuICAgICAgdGhpcy5ob29rcy5mb3JFYWNoKGhvb2sgPT4gaG9vay5saXN0LmhpZGUoKSk7XG4gICAgfSxcblxuICAgIHJlbW92ZUV2ZW50czogZnVuY3Rpb24oKXtcbiAgICAgIGRvY3VtZW50LnJlbW92ZUV2ZW50TGlzdGVuZXIoJ2NsaWNrJywgdGhpcy5ldmVudFdyYXBwZXIuZG9jdW1lbnRDbGlja2VkKTtcbiAgICB9LFxuXG4gICAgY2hhbmdlSG9va0xpc3Q6IGZ1bmN0aW9uKHRyaWdnZXIsIGxpc3QsIHBsdWdpbnMsIGNvbmZpZykge1xuICAgICAgY29uc3QgYXZhaWxhYmxlVHJpZ2dlciA9ICB0eXBlb2YgdHJpZ2dlciA9PT0gJ3N0cmluZycgPyBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCh0cmlnZ2VyKSA6IHRyaWdnZXI7XG5cblxuICAgICAgdGhpcy5ob29rcy5mb3JFYWNoKChob29rLCBpKSA9PiB7XG4gICAgICAgIGhvb2subGlzdC5saXN0LmRhdGFzZXQuZHJvcGRvd25BY3RpdmUgPSBmYWxzZTtcblxuICAgICAgICBpZiAoaG9vay50cmlnZ2VyICE9PSBhdmFpbGFibGVUcmlnZ2VyKSByZXR1cm47XG5cbiAgICAgICAgaG9vay5kZXN0cm95KCk7XG4gICAgICAgIHRoaXMuaG9va3Muc3BsaWNlKGksIDEpO1xuICAgICAgICB0aGlzLmFkZEhvb2soYXZhaWxhYmxlVHJpZ2dlciwgbGlzdCwgcGx1Z2lucywgY29uZmlnKTtcbiAgICAgIH0pO1xuICAgIH0sXG5cbiAgICBhZGRIb29rOiBmdW5jdGlvbihob29rLCBsaXN0LCBwbHVnaW5zLCBjb25maWcpIHtcbiAgICAgIGNvbnN0IGF2YWlsYWJsZUhvb2sgPSB0eXBlb2YgaG9vayA9PT0gJ3N0cmluZycgPyBkb2N1bWVudC5xdWVyeVNlbGVjdG9yKGhvb2spIDogaG9vaztcbiAgICAgIGxldCBhdmFpbGFibGVMaXN0O1xuXG4gICAgICBpZiAodHlwZW9mIGxpc3QgPT09ICdzdHJpbmcnKSB7XG4gICAgICAgIGF2YWlsYWJsZUxpc3QgPSBkb2N1bWVudC5xdWVyeVNlbGVjdG9yKGxpc3QpO1xuICAgICAgfSBlbHNlIGlmIChsaXN0IGluc3RhbmNlb2YgRWxlbWVudCkge1xuICAgICAgICBhdmFpbGFibGVMaXN0ID0gbGlzdDtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIGF2YWlsYWJsZUxpc3QgPSBkb2N1bWVudC5xdWVyeVNlbGVjdG9yKGhvb2suZGF0YXNldFt1dGlscy50b0NhbWVsQ2FzZShEQVRBX1RSSUdHRVIpXSk7XG4gICAgICB9XG5cbiAgICAgIGF2YWlsYWJsZUxpc3QuZGF0YXNldC5kcm9wZG93bkFjdGl2ZSA9IHRydWU7XG5cbiAgICAgIGNvbnN0IEhvb2tPYmplY3QgPSBhdmFpbGFibGVIb29rLnRhZ05hbWUgPT09ICdJTlBVVCcgPyBIb29rSW5wdXQgOiBIb29rQnV0dG9uO1xuICAgICAgdGhpcy5ob29rcy5wdXNoKG5ldyBIb29rT2JqZWN0KGF2YWlsYWJsZUhvb2ssIGF2YWlsYWJsZUxpc3QsIHBsdWdpbnMsIGNvbmZpZykpO1xuXG4gICAgICByZXR1cm4gdGhpcztcbiAgICB9LFxuXG4gICAgYWRkSG9va3M6IGZ1bmN0aW9uKGhvb2tzLCBwbHVnaW5zLCBjb25maWcpIHtcbiAgICAgIGhvb2tzLmZvckVhY2goaG9vayA9PiB0aGlzLmFkZEhvb2soaG9vaywgbnVsbCwgcGx1Z2lucywgY29uZmlnKSk7XG4gICAgICByZXR1cm4gdGhpcztcbiAgICB9LFxuXG4gICAgc2V0Q29uZmlnOiBmdW5jdGlvbihvYmope1xuICAgICAgdGhpcy5jb25maWcgPSBvYmo7XG4gICAgfSxcblxuICAgIGZpcmVSZWFkeTogZnVuY3Rpb24oKSB7XG4gICAgICBjb25zdCByZWFkeUV2ZW50ID0gbmV3IEN1c3RvbUV2ZW50KCdyZWFkeS5kbCcsIHtcbiAgICAgICAgZGV0YWlsOiB7XG4gICAgICAgICAgZHJvcGRvd246IHRoaXMsXG4gICAgICAgIH0sXG4gICAgICB9KTtcbiAgICAgIGRvY3VtZW50LmRpc3BhdGNoRXZlbnQocmVhZHlFdmVudCk7XG5cbiAgICAgIHRoaXMucmVhZHkgPSB0cnVlO1xuICAgIH0sXG5cbiAgICBpbml0OiBmdW5jdGlvbiAoKSB7XG4gICAgICB0aGlzLmFkZEV2ZW50cygpO1xuXG4gICAgICB0aGlzLmZpcmVSZWFkeSgpO1xuXG4gICAgICB0aGlzLnF1ZXVlZERhdGEuZm9yRWFjaChkYXRhID0+IHRoaXMuYWRkRGF0YShkYXRhKSk7XG4gICAgICB0aGlzLnF1ZXVlZERhdGEgPSBbXTtcblxuICAgICAgcmV0dXJuIHRoaXM7XG4gICAgfSxcbiAgfSk7XG5cbiAgcmV0dXJuIERyb3BMYWI7XG59O1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL2Ryb3BsYWIuanMiLCJpbXBvcnQgY29uc3RhbnRzIGZyb20gJy4vY29uc3RhbnRzJztcblxuZXhwb3J0IGRlZmF1bHQgZnVuY3Rpb24gKCkge1xuICB2YXIgY3VycmVudEtleTtcbiAgdmFyIGN1cnJlbnRGb2N1cztcbiAgdmFyIGlzVXBBcnJvdyA9IGZhbHNlO1xuICB2YXIgaXNEb3duQXJyb3cgPSBmYWxzZTtcbiAgdmFyIHJlbW92ZUhpZ2hsaWdodCA9IGZ1bmN0aW9uIHJlbW92ZUhpZ2hsaWdodChsaXN0KSB7XG4gICAgdmFyIGl0ZW1FbGVtZW50cyA9IEFycmF5LnByb3RvdHlwZS5zbGljZS5jYWxsKGxpc3QubGlzdC5xdWVyeVNlbGVjdG9yQWxsKCdsaTpub3QoLmRpdmlkZXIpJyksIDApO1xuICAgIHZhciBsaXN0SXRlbXMgPSBbXTtcbiAgICBmb3IodmFyIGkgPSAwOyBpIDwgaXRlbUVsZW1lbnRzLmxlbmd0aDsgaSsrKSB7XG4gICAgICB2YXIgbGlzdEl0ZW0gPSBpdGVtRWxlbWVudHNbaV07XG4gICAgICBsaXN0SXRlbS5jbGFzc0xpc3QucmVtb3ZlKGNvbnN0YW50cy5BQ1RJVkVfQ0xBU1MpO1xuXG4gICAgICBpZiAobGlzdEl0ZW0uc3R5bGUuZGlzcGxheSAhPT0gJ25vbmUnKSB7XG4gICAgICAgIGxpc3RJdGVtcy5wdXNoKGxpc3RJdGVtKTtcbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIGxpc3RJdGVtcztcbiAgfTtcblxuICB2YXIgc2V0TWVudUZvckFycm93cyA9IGZ1bmN0aW9uIHNldE1lbnVGb3JBcnJvd3MobGlzdCkge1xuICAgIHZhciBsaXN0SXRlbXMgPSByZW1vdmVIaWdobGlnaHQobGlzdCk7XG4gICAgaWYobGlzdC5jdXJyZW50SW5kZXg+MCl7XG4gICAgICBpZighbGlzdEl0ZW1zW2xpc3QuY3VycmVudEluZGV4LTFdKXtcbiAgICAgICAgbGlzdC5jdXJyZW50SW5kZXggPSBsaXN0LmN1cnJlbnRJbmRleC0xO1xuICAgICAgfVxuXG4gICAgICBpZiAobGlzdEl0ZW1zW2xpc3QuY3VycmVudEluZGV4LTFdKSB7XG4gICAgICAgIHZhciBlbCA9IGxpc3RJdGVtc1tsaXN0LmN1cnJlbnRJbmRleC0xXTtcbiAgICAgICAgdmFyIGZpbHRlckRyb3Bkb3duRWwgPSBlbC5jbG9zZXN0KCcuZmlsdGVyLWRyb3Bkb3duJyk7XG4gICAgICAgIGVsLmNsYXNzTGlzdC5hZGQoY29uc3RhbnRzLkFDVElWRV9DTEFTUyk7XG5cbiAgICAgICAgaWYgKGZpbHRlckRyb3Bkb3duRWwpIHtcbiAgICAgICAgICB2YXIgZmlsdGVyRHJvcGRvd25Cb3R0b20gPSBmaWx0ZXJEcm9wZG93bkVsLm9mZnNldEhlaWdodDtcbiAgICAgICAgICB2YXIgZWxPZmZzZXRUb3AgPSBlbC5vZmZzZXRUb3AgLSAzMDtcblxuICAgICAgICAgIGlmIChlbE9mZnNldFRvcCA+IGZpbHRlckRyb3Bkb3duQm90dG9tKSB7XG4gICAgICAgICAgICBmaWx0ZXJEcm9wZG93bkVsLnNjcm9sbFRvcCA9IGVsT2Zmc2V0VG9wIC0gZmlsdGVyRHJvcGRvd25Cb3R0b207XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuICB9O1xuXG4gIHZhciBtb3VzZWRvd24gPSBmdW5jdGlvbiBtb3VzZWRvd24oZSkge1xuICAgIHZhciBsaXN0ID0gZS5kZXRhaWwuaG9vay5saXN0O1xuICAgIHJlbW92ZUhpZ2hsaWdodChsaXN0KTtcbiAgICBsaXN0LnNob3coKTtcbiAgICBsaXN0LmN1cnJlbnRJbmRleCA9IDA7XG4gICAgaXNVcEFycm93ID0gZmFsc2U7XG4gICAgaXNEb3duQXJyb3cgPSBmYWxzZTtcbiAgfTtcbiAgdmFyIHNlbGVjdEl0ZW0gPSBmdW5jdGlvbiBzZWxlY3RJdGVtKGxpc3QpIHtcbiAgICB2YXIgbGlzdEl0ZW1zID0gcmVtb3ZlSGlnaGxpZ2h0KGxpc3QpO1xuICAgIHZhciBjdXJyZW50SXRlbSA9IGxpc3RJdGVtc1tsaXN0LmN1cnJlbnRJbmRleC0xXTtcbiAgICB2YXIgbGlzdEV2ZW50ID0gbmV3IEN1c3RvbUV2ZW50KCdjbGljay5kbCcsIHtcbiAgICAgIGRldGFpbDoge1xuICAgICAgICBsaXN0OiBsaXN0LFxuICAgICAgICBzZWxlY3RlZDogY3VycmVudEl0ZW0sXG4gICAgICAgIGRhdGE6IGN1cnJlbnRJdGVtLmRhdGFzZXQsXG4gICAgICB9LFxuICAgIH0pO1xuICAgIGxpc3QubGlzdC5kaXNwYXRjaEV2ZW50KGxpc3RFdmVudCk7XG4gICAgbGlzdC5oaWRlKCk7XG4gIH1cblxuICB2YXIga2V5ZG93biA9IGZ1bmN0aW9uIGtleWRvd24oZSl7XG4gICAgdmFyIHR5cGVkT24gPSBlLnRhcmdldDtcbiAgICB2YXIgbGlzdCA9IGUuZGV0YWlsLmhvb2subGlzdDtcbiAgICB2YXIgY3VycmVudEluZGV4ID0gbGlzdC5jdXJyZW50SW5kZXg7XG4gICAgaXNVcEFycm93ID0gZmFsc2U7XG4gICAgaXNEb3duQXJyb3cgPSBmYWxzZTtcblxuICAgIGlmKGUuZGV0YWlsLndoaWNoKXtcbiAgICAgIGN1cnJlbnRLZXkgPSBlLmRldGFpbC53aGljaDtcbiAgICAgIGlmKGN1cnJlbnRLZXkgPT09IDEzKXtcbiAgICAgICAgc2VsZWN0SXRlbShlLmRldGFpbC5ob29rLmxpc3QpO1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG4gICAgICBpZihjdXJyZW50S2V5ID09PSAzOCkge1xuICAgICAgICBpc1VwQXJyb3cgPSB0cnVlO1xuICAgICAgfVxuICAgICAgaWYoY3VycmVudEtleSA9PT0gNDApIHtcbiAgICAgICAgaXNEb3duQXJyb3cgPSB0cnVlO1xuICAgICAgfVxuICAgIH0gZWxzZSBpZihlLmRldGFpbC5rZXkpIHtcbiAgICAgIGN1cnJlbnRLZXkgPSBlLmRldGFpbC5rZXk7XG4gICAgICBpZihjdXJyZW50S2V5ID09PSAnRW50ZXInKXtcbiAgICAgICAgc2VsZWN0SXRlbShlLmRldGFpbC5ob29rLmxpc3QpO1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG4gICAgICBpZihjdXJyZW50S2V5ID09PSAnQXJyb3dVcCcpIHtcbiAgICAgICAgaXNVcEFycm93ID0gdHJ1ZTtcbiAgICAgIH1cbiAgICAgIGlmKGN1cnJlbnRLZXkgPT09ICdBcnJvd0Rvd24nKSB7XG4gICAgICAgIGlzRG93bkFycm93ID0gdHJ1ZTtcbiAgICAgIH1cbiAgICB9XG4gICAgaWYoaXNVcEFycm93KXsgY3VycmVudEluZGV4LS07IH1cbiAgICBpZihpc0Rvd25BcnJvdyl7IGN1cnJlbnRJbmRleCsrOyB9XG4gICAgaWYoY3VycmVudEluZGV4IDwgMCl7IGN1cnJlbnRJbmRleCA9IDA7IH1cbiAgICBsaXN0LmN1cnJlbnRJbmRleCA9IGN1cnJlbnRJbmRleDtcbiAgICBzZXRNZW51Rm9yQXJyb3dzKGUuZGV0YWlsLmhvb2subGlzdCk7XG4gIH07XG5cbiAgZG9jdW1lbnQuYWRkRXZlbnRMaXN0ZW5lcignbW91c2Vkb3duLmRsJywgbW91c2Vkb3duKTtcbiAgZG9jdW1lbnQuYWRkRXZlbnRMaXN0ZW5lcigna2V5ZG93bi5kbCcsIGtleWRvd24pO1xufVxuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL2tleWJvYXJkLmpzIiwiaW1wb3J0ICdjdXN0b20tZXZlbnQtcG9seWZpbGwnO1xuaW1wb3J0IHV0aWxzIGZyb20gJy4vdXRpbHMnO1xuaW1wb3J0IGNvbnN0YW50cyBmcm9tICcuLi9zcmMvY29uc3RhbnRzJztcblxudmFyIERyb3BEb3duID0gZnVuY3Rpb24obGlzdCkge1xuICB0aGlzLmN1cnJlbnRJbmRleCA9IDA7XG4gIHRoaXMuaGlkZGVuID0gdHJ1ZTtcbiAgdGhpcy5saXN0ID0gdHlwZW9mIGxpc3QgPT09ICdzdHJpbmcnID8gZG9jdW1lbnQucXVlcnlTZWxlY3RvcihsaXN0KSA6IGxpc3Q7XG4gIHRoaXMuaXRlbXMgPSBbXTtcblxuICB0aGlzLmV2ZW50V3JhcHBlciA9IHt9O1xuXG4gIHRoaXMuZ2V0SXRlbXMoKTtcbiAgdGhpcy5pbml0VGVtcGxhdGVTdHJpbmcoKTtcbiAgdGhpcy5hZGRFdmVudHMoKTtcblxuICB0aGlzLmluaXRpYWxTdGF0ZSA9IGxpc3QuaW5uZXJIVE1MO1xufTtcblxuT2JqZWN0LmFzc2lnbihEcm9wRG93bi5wcm90b3R5cGUsIHtcbiAgZ2V0SXRlbXM6IGZ1bmN0aW9uKCkge1xuICAgIHRoaXMuaXRlbXMgPSBbXS5zbGljZS5jYWxsKHRoaXMubGlzdC5xdWVyeVNlbGVjdG9yQWxsKCdsaScpKTtcbiAgICByZXR1cm4gdGhpcy5pdGVtcztcbiAgfSxcblxuICBpbml0VGVtcGxhdGVTdHJpbmc6IGZ1bmN0aW9uKCkge1xuICAgIHZhciBpdGVtcyA9IHRoaXMuaXRlbXMgfHwgdGhpcy5nZXRJdGVtcygpO1xuXG4gICAgdmFyIHRlbXBsYXRlU3RyaW5nID0gJyc7XG4gICAgaWYgKGl0ZW1zLmxlbmd0aCA+IDApIHRlbXBsYXRlU3RyaW5nID0gaXRlbXNbaXRlbXMubGVuZ3RoIC0gMV0ub3V0ZXJIVE1MO1xuICAgIHRoaXMudGVtcGxhdGVTdHJpbmcgPSB0ZW1wbGF0ZVN0cmluZztcblxuICAgIHJldHVybiB0aGlzLnRlbXBsYXRlU3RyaW5nO1xuICB9LFxuXG4gIGNsaWNrRXZlbnQ6IGZ1bmN0aW9uKGUpIHtcbiAgICB2YXIgc2VsZWN0ZWQgPSB1dGlscy5jbG9zZXN0KGUudGFyZ2V0LCAnTEknKTtcbiAgICBpZiAoIXNlbGVjdGVkKSByZXR1cm47XG5cbiAgICB0aGlzLmFkZFNlbGVjdGVkQ2xhc3Moc2VsZWN0ZWQpO1xuXG4gICAgZS5wcmV2ZW50RGVmYXVsdCgpO1xuICAgIHRoaXMuaGlkZSgpO1xuXG4gICAgdmFyIGxpc3RFdmVudCA9IG5ldyBDdXN0b21FdmVudCgnY2xpY2suZGwnLCB7XG4gICAgICBkZXRhaWw6IHtcbiAgICAgICAgbGlzdDogdGhpcyxcbiAgICAgICAgc2VsZWN0ZWQ6IHNlbGVjdGVkLFxuICAgICAgICBkYXRhOiBlLnRhcmdldC5kYXRhc2V0LFxuICAgICAgfSxcbiAgICB9KTtcbiAgICB0aGlzLmxpc3QuZGlzcGF0Y2hFdmVudChsaXN0RXZlbnQpO1xuICB9LFxuXG4gIGFkZFNlbGVjdGVkQ2xhc3M6IGZ1bmN0aW9uIChzZWxlY3RlZCkge1xuICAgIHRoaXMucmVtb3ZlU2VsZWN0ZWRDbGFzc2VzKCk7XG4gICAgc2VsZWN0ZWQuY2xhc3NMaXN0LmFkZChjb25zdGFudHMuU0VMRUNURURfQ0xBU1MpO1xuICB9LFxuXG4gIHJlbW92ZVNlbGVjdGVkQ2xhc3NlczogZnVuY3Rpb24gKCkge1xuICAgIGNvbnN0IGl0ZW1zID0gdGhpcy5pdGVtcyB8fCB0aGlzLmdldEl0ZW1zKCk7XG5cbiAgICBpdGVtcy5mb3JFYWNoKChpdGVtKSA9PiB7XG4gICAgICBpdGVtLmNsYXNzTGlzdC5yZW1vdmUoY29uc3RhbnRzLlNFTEVDVEVEX0NMQVNTKVxuICAgIH0pO1xuICB9LFxuXG4gIGFkZEV2ZW50czogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5ldmVudFdyYXBwZXIuY2xpY2tFdmVudCA9IHRoaXMuY2xpY2tFdmVudC5iaW5kKHRoaXMpXG4gICAgdGhpcy5saXN0LmFkZEV2ZW50TGlzdGVuZXIoJ2NsaWNrJywgdGhpcy5ldmVudFdyYXBwZXIuY2xpY2tFdmVudCk7XG4gIH0sXG5cbiAgdG9nZ2xlOiBmdW5jdGlvbigpIHtcbiAgICB0aGlzLmhpZGRlbiA/IHRoaXMuc2hvdygpIDogdGhpcy5oaWRlKCk7XG4gIH0sXG5cbiAgc2V0RGF0YTogZnVuY3Rpb24oZGF0YSkge1xuICAgIHRoaXMuZGF0YSA9IGRhdGE7XG4gICAgdGhpcy5yZW5kZXIoZGF0YSk7XG4gIH0sXG5cbiAgYWRkRGF0YTogZnVuY3Rpb24oZGF0YSkge1xuICAgIHRoaXMuZGF0YSA9ICh0aGlzLmRhdGEgfHwgW10pLmNvbmNhdChkYXRhKTtcbiAgICB0aGlzLnJlbmRlcih0aGlzLmRhdGEpO1xuICB9LFxuXG4gIHJlbmRlcjogZnVuY3Rpb24oZGF0YSkge1xuICAgIGNvbnN0IGNoaWxkcmVuID0gZGF0YSA/IGRhdGEubWFwKHRoaXMucmVuZGVyQ2hpbGRyZW4uYmluZCh0aGlzKSkgOiBbXTtcbiAgICBjb25zdCByZW5kZXJhYmxlTGlzdCA9IHRoaXMubGlzdC5xdWVyeVNlbGVjdG9yKCd1bFtkYXRhLWR5bmFtaWNdJykgfHwgdGhpcy5saXN0O1xuXG4gICAgcmVuZGVyYWJsZUxpc3QuaW5uZXJIVE1MID0gY2hpbGRyZW4uam9pbignJyk7XG4gIH0sXG5cbiAgcmVuZGVyQ2hpbGRyZW46IGZ1bmN0aW9uKGRhdGEpIHtcbiAgICB2YXIgaHRtbCA9IHV0aWxzLnQodGhpcy50ZW1wbGF0ZVN0cmluZywgZGF0YSk7XG4gICAgdmFyIHRlbXBsYXRlID0gZG9jdW1lbnQuY3JlYXRlRWxlbWVudCgnZGl2Jyk7XG5cbiAgICB0ZW1wbGF0ZS5pbm5lckhUTUwgPSBodG1sO1xuICAgIHRoaXMuc2V0SW1hZ2VzU3JjKHRlbXBsYXRlKTtcbiAgICB0ZW1wbGF0ZS5maXJzdENoaWxkLnN0eWxlLmRpc3BsYXkgPSBkYXRhLmRyb3BsYWJfaGlkZGVuID8gJ25vbmUnIDogJ2Jsb2NrJztcblxuICAgIHJldHVybiB0ZW1wbGF0ZS5maXJzdENoaWxkLm91dGVySFRNTDtcbiAgfSxcblxuICBzZXRJbWFnZXNTcmM6IGZ1bmN0aW9uKHRlbXBsYXRlKSB7XG4gICAgY29uc3QgaW1hZ2VzID0gW10uc2xpY2UuY2FsbCh0ZW1wbGF0ZS5xdWVyeVNlbGVjdG9yQWxsKCdpbWdbZGF0YS1zcmNdJykpO1xuXG4gICAgaW1hZ2VzLmZvckVhY2goKGltYWdlKSA9PiB7XG4gICAgICBpbWFnZS5zcmMgPSBpbWFnZS5nZXRBdHRyaWJ1dGUoJ2RhdGEtc3JjJyk7XG4gICAgICBpbWFnZS5yZW1vdmVBdHRyaWJ1dGUoJ2RhdGEtc3JjJyk7XG4gICAgfSk7XG4gIH0sXG5cbiAgc2hvdzogZnVuY3Rpb24oKSB7XG4gICAgaWYgKCF0aGlzLmhpZGRlbikgcmV0dXJuO1xuICAgIHRoaXMubGlzdC5zdHlsZS5kaXNwbGF5ID0gJ2Jsb2NrJztcbiAgICB0aGlzLmN1cnJlbnRJbmRleCA9IDA7XG4gICAgdGhpcy5oaWRkZW4gPSBmYWxzZTtcbiAgfSxcblxuICBoaWRlOiBmdW5jdGlvbigpIHtcbiAgICBpZiAodGhpcy5oaWRkZW4pIHJldHVybjtcbiAgICB0aGlzLmxpc3Quc3R5bGUuZGlzcGxheSA9ICdub25lJztcbiAgICB0aGlzLmN1cnJlbnRJbmRleCA9IDA7XG4gICAgdGhpcy5oaWRkZW4gPSB0cnVlO1xuICB9LFxuXG4gIHRvZ2dsZTogZnVuY3Rpb24gKCkge1xuICAgIHRoaXMuaGlkZGVuID8gdGhpcy5zaG93KCkgOiB0aGlzLmhpZGUoKTtcbiAgfSxcblxuICBkZXN0cm95OiBmdW5jdGlvbigpIHtcbiAgICB0aGlzLmhpZGUoKTtcbiAgICB0aGlzLmxpc3QucmVtb3ZlRXZlbnRMaXN0ZW5lcignY2xpY2snLCB0aGlzLmV2ZW50V3JhcHBlci5jbGlja0V2ZW50KTtcbiAgfVxufSk7XG5cbmV4cG9ydCBkZWZhdWx0IERyb3BEb3duO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL2Ryb3Bkb3duLmpzIiwiaW1wb3J0ICdjdXN0b20tZXZlbnQtcG9seWZpbGwnO1xuaW1wb3J0IEhvb2sgZnJvbSAnLi9ob29rJztcblxudmFyIEhvb2tCdXR0b24gPSBmdW5jdGlvbih0cmlnZ2VyLCBsaXN0LCBwbHVnaW5zLCBjb25maWcpIHtcbiAgSG9vay5jYWxsKHRoaXMsIHRyaWdnZXIsIGxpc3QsIHBsdWdpbnMsIGNvbmZpZyk7XG5cbiAgdGhpcy50eXBlID0gJ2J1dHRvbic7XG4gIHRoaXMuZXZlbnQgPSAnY2xpY2snO1xuXG4gIHRoaXMuZXZlbnRXcmFwcGVyID0ge307XG5cbiAgdGhpcy5hZGRFdmVudHMoKTtcbiAgdGhpcy5hZGRQbHVnaW5zKCk7XG59O1xuXG5Ib29rQnV0dG9uLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoSG9vay5wcm90b3R5cGUpO1xuXG5PYmplY3QuYXNzaWduKEhvb2tCdXR0b24ucHJvdG90eXBlLCB7XG4gIGFkZFBsdWdpbnM6IGZ1bmN0aW9uKCkge1xuICAgIHRoaXMucGx1Z2lucy5mb3JFYWNoKHBsdWdpbiA9PiBwbHVnaW4uaW5pdCh0aGlzKSk7XG4gIH0sXG5cbiAgY2xpY2tlZDogZnVuY3Rpb24oZSl7XG4gICAgdmFyIGJ1dHRvbkV2ZW50ID0gbmV3IEN1c3RvbUV2ZW50KCdjbGljay5kbCcsIHtcbiAgICAgIGRldGFpbDoge1xuICAgICAgICBob29rOiB0aGlzLFxuICAgICAgfSxcbiAgICAgIGJ1YmJsZXM6IHRydWUsXG4gICAgICBjYW5jZWxhYmxlOiB0cnVlXG4gICAgfSk7XG4gICAgZS50YXJnZXQuZGlzcGF0Y2hFdmVudChidXR0b25FdmVudCk7XG5cbiAgICB0aGlzLmxpc3QudG9nZ2xlKCk7XG4gIH0sXG5cbiAgYWRkRXZlbnRzOiBmdW5jdGlvbigpe1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLmNsaWNrZWQgPSB0aGlzLmNsaWNrZWQuYmluZCh0aGlzKTtcbiAgICB0aGlzLnRyaWdnZXIuYWRkRXZlbnRMaXN0ZW5lcignY2xpY2snLCB0aGlzLmV2ZW50V3JhcHBlci5jbGlja2VkKTtcbiAgfSxcblxuICByZW1vdmVFdmVudHM6IGZ1bmN0aW9uKCl7XG4gICAgdGhpcy50cmlnZ2VyLnJlbW92ZUV2ZW50TGlzdGVuZXIoJ2NsaWNrJywgdGhpcy5ldmVudFdyYXBwZXIuY2xpY2tlZCk7XG4gIH0sXG5cbiAgcmVzdG9yZUluaXRpYWxTdGF0ZTogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5saXN0Lmxpc3QuaW5uZXJIVE1MID0gdGhpcy5saXN0LmluaXRpYWxTdGF0ZTtcbiAgfSxcblxuICByZW1vdmVQbHVnaW5zOiBmdW5jdGlvbigpIHtcbiAgICB0aGlzLnBsdWdpbnMuZm9yRWFjaChwbHVnaW4gPT4gcGx1Z2luLmRlc3Ryb3koKSk7XG4gIH0sXG5cbiAgZGVzdHJveTogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5yZXN0b3JlSW5pdGlhbFN0YXRlKCk7XG5cbiAgICB0aGlzLnJlbW92ZUV2ZW50cygpO1xuICAgIHRoaXMucmVtb3ZlUGx1Z2lucygpO1xuICB9LFxuXG4gIGNvbnN0cnVjdG9yOiBIb29rQnV0dG9uLFxufSk7XG5cblxuZXhwb3J0IGRlZmF1bHQgSG9va0J1dHRvbjtcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyAuL3NyYy9ob29rX2J1dHRvbi5qcyIsImltcG9ydCAnY3VzdG9tLWV2ZW50LXBvbHlmaWxsJztcbmltcG9ydCBIb29rIGZyb20gJy4vaG9vayc7XG5cbnZhciBIb29rSW5wdXQgPSBmdW5jdGlvbih0cmlnZ2VyLCBsaXN0LCBwbHVnaW5zLCBjb25maWcpIHtcbiAgSG9vay5jYWxsKHRoaXMsIHRyaWdnZXIsIGxpc3QsIHBsdWdpbnMsIGNvbmZpZyk7XG5cbiAgdGhpcy50eXBlID0gJ2lucHV0JztcbiAgdGhpcy5ldmVudCA9ICdpbnB1dCc7XG5cbiAgdGhpcy5ldmVudFdyYXBwZXIgPSB7fTtcblxuICB0aGlzLmFkZEV2ZW50cygpO1xuICB0aGlzLmFkZFBsdWdpbnMoKTtcbn07XG5cbk9iamVjdC5hc3NpZ24oSG9va0lucHV0LnByb3RvdHlwZSwge1xuICBhZGRQbHVnaW5zOiBmdW5jdGlvbigpIHtcbiAgICB0aGlzLnBsdWdpbnMuZm9yRWFjaChwbHVnaW4gPT4gcGx1Z2luLmluaXQodGhpcykpO1xuICB9LFxuXG4gIGFkZEV2ZW50czogZnVuY3Rpb24oKXtcbiAgICB0aGlzLmV2ZW50V3JhcHBlci5tb3VzZWRvd24gPSB0aGlzLm1vdXNlZG93bi5iaW5kKHRoaXMpO1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLmlucHV0ID0gdGhpcy5pbnB1dC5iaW5kKHRoaXMpO1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLmtleXVwID0gdGhpcy5rZXl1cC5iaW5kKHRoaXMpO1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLmtleWRvd24gPSB0aGlzLmtleWRvd24uYmluZCh0aGlzKTtcblxuICAgIHRoaXMudHJpZ2dlci5hZGRFdmVudExpc3RlbmVyKCdtb3VzZWRvd24nLCB0aGlzLmV2ZW50V3JhcHBlci5tb3VzZWRvd24pO1xuICAgIHRoaXMudHJpZ2dlci5hZGRFdmVudExpc3RlbmVyKCdpbnB1dCcsIHRoaXMuZXZlbnRXcmFwcGVyLmlucHV0KTtcbiAgICB0aGlzLnRyaWdnZXIuYWRkRXZlbnRMaXN0ZW5lcigna2V5dXAnLCB0aGlzLmV2ZW50V3JhcHBlci5rZXl1cCk7XG4gICAgdGhpcy50cmlnZ2VyLmFkZEV2ZW50TGlzdGVuZXIoJ2tleWRvd24nLCB0aGlzLmV2ZW50V3JhcHBlci5rZXlkb3duKTtcbiAgfSxcblxuICByZW1vdmVFdmVudHM6IGZ1bmN0aW9uKCkge1xuICAgIHRoaXMuaGFzUmVtb3ZlZEV2ZW50cyA9IHRydWU7XG5cbiAgICB0aGlzLnRyaWdnZXIucmVtb3ZlRXZlbnRMaXN0ZW5lcignbW91c2Vkb3duJywgdGhpcy5ldmVudFdyYXBwZXIubW91c2Vkb3duKTtcbiAgICB0aGlzLnRyaWdnZXIucmVtb3ZlRXZlbnRMaXN0ZW5lcignaW5wdXQnLCB0aGlzLmV2ZW50V3JhcHBlci5pbnB1dCk7XG4gICAgdGhpcy50cmlnZ2VyLnJlbW92ZUV2ZW50TGlzdGVuZXIoJ2tleXVwJywgdGhpcy5ldmVudFdyYXBwZXIua2V5dXApO1xuICAgIHRoaXMudHJpZ2dlci5yZW1vdmVFdmVudExpc3RlbmVyKCdrZXlkb3duJywgdGhpcy5ldmVudFdyYXBwZXIua2V5ZG93bik7XG4gIH0sXG5cbiAgaW5wdXQ6IGZ1bmN0aW9uKGUpIHtcbiAgICBpZih0aGlzLmhhc1JlbW92ZWRFdmVudHMpIHJldHVybjtcblxuICAgIHRoaXMubGlzdC5zaG93KCk7XG5cbiAgICBjb25zdCBpbnB1dEV2ZW50ID0gbmV3IEN1c3RvbUV2ZW50KCdpbnB1dC5kbCcsIHtcbiAgICAgIGRldGFpbDoge1xuICAgICAgICBob29rOiB0aGlzLFxuICAgICAgICB0ZXh0OiBlLnRhcmdldC52YWx1ZSxcbiAgICAgIH0sXG4gICAgICBidWJibGVzOiB0cnVlLFxuICAgICAgY2FuY2VsYWJsZTogdHJ1ZVxuICAgIH0pO1xuICAgIGUudGFyZ2V0LmRpc3BhdGNoRXZlbnQoaW5wdXRFdmVudCk7XG4gIH0sXG5cbiAgbW91c2Vkb3duOiBmdW5jdGlvbihlKSB7XG4gICAgaWYgKHRoaXMuaGFzUmVtb3ZlZEV2ZW50cykgcmV0dXJuO1xuXG4gICAgY29uc3QgbW91c2VFdmVudCA9IG5ldyBDdXN0b21FdmVudCgnbW91c2Vkb3duLmRsJywge1xuICAgICAgZGV0YWlsOiB7XG4gICAgICAgIGhvb2s6IHRoaXMsXG4gICAgICAgIHRleHQ6IGUudGFyZ2V0LnZhbHVlLFxuICAgICAgfSxcbiAgICAgIGJ1YmJsZXM6IHRydWUsXG4gICAgICBjYW5jZWxhYmxlOiB0cnVlLFxuICAgIH0pO1xuICAgIGUudGFyZ2V0LmRpc3BhdGNoRXZlbnQobW91c2VFdmVudCk7XG4gIH0sXG5cbiAga2V5dXA6IGZ1bmN0aW9uKGUpIHtcbiAgICBpZiAodGhpcy5oYXNSZW1vdmVkRXZlbnRzKSByZXR1cm47XG5cbiAgICB0aGlzLmtleUV2ZW50KGUsICdrZXl1cC5kbCcpO1xuICB9LFxuXG4gIGtleWRvd246IGZ1bmN0aW9uKGUpIHtcbiAgICBpZiAodGhpcy5oYXNSZW1vdmVkRXZlbnRzKSByZXR1cm47XG5cbiAgICB0aGlzLmtleUV2ZW50KGUsICdrZXlkb3duLmRsJyk7XG4gIH0sXG5cbiAga2V5RXZlbnQ6IGZ1bmN0aW9uKGUsIGV2ZW50TmFtZSkge1xuICAgIHRoaXMubGlzdC5zaG93KCk7XG5cbiAgICBjb25zdCBrZXlFdmVudCA9IG5ldyBDdXN0b21FdmVudChldmVudE5hbWUsIHtcbiAgICAgIGRldGFpbDoge1xuICAgICAgICBob29rOiB0aGlzLFxuICAgICAgICB0ZXh0OiBlLnRhcmdldC52YWx1ZSxcbiAgICAgICAgd2hpY2g6IGUud2hpY2gsXG4gICAgICAgIGtleTogZS5rZXksXG4gICAgICB9LFxuICAgICAgYnViYmxlczogdHJ1ZSxcbiAgICAgIGNhbmNlbGFibGU6IHRydWUsXG4gICAgfSk7XG4gICAgZS50YXJnZXQuZGlzcGF0Y2hFdmVudChrZXlFdmVudCk7XG4gIH0sXG5cbiAgcmVzdG9yZUluaXRpYWxTdGF0ZTogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5saXN0Lmxpc3QuaW5uZXJIVE1MID0gdGhpcy5saXN0LmluaXRpYWxTdGF0ZTtcbiAgfSxcblxuICByZW1vdmVQbHVnaW5zOiBmdW5jdGlvbigpIHtcbiAgICB0aGlzLnBsdWdpbnMuZm9yRWFjaChwbHVnaW4gPT4gcGx1Z2luLmRlc3Ryb3koKSk7XG4gIH0sXG5cbiAgZGVzdHJveTogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5yZXN0b3JlSW5pdGlhbFN0YXRlKCk7XG5cbiAgICB0aGlzLnJlbW92ZUV2ZW50cygpO1xuICAgIHRoaXMucmVtb3ZlUGx1Z2lucygpO1xuXG4gICAgdGhpcy5saXN0LmRlc3Ryb3koKTtcbiAgfVxufSk7XG5cbmV4cG9ydCBkZWZhdWx0IEhvb2tJbnB1dDtcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyAuL3NyYy9ob29rX2lucHV0LmpzIiwiaW1wb3J0IERyb3BMYWIgZnJvbSAnLi9kcm9wbGFiJztcbmltcG9ydCBjb25zdGFudHMgZnJvbSAnLi9jb25zdGFudHMnO1xuaW1wb3J0IEtleWJvYXJkIGZyb20gJy4va2V5Ym9hcmQnO1xuXG5jb25zdCBEQVRBX1RSSUdHRVIgPSBjb25zdGFudHMuREFUQV9UUklHR0VSO1xuY29uc3Qga2V5Ym9hcmQgPSBLZXlib2FyZCgpO1xuXG5jb25zdCBzZXR1cCA9IGZ1bmN0aW9uICgpIHtcbiAgd2luZG93LkRyb3BMYWIgPSBEcm9wTGFiKCk7XG59O1xuXG5zZXR1cCgpO1xuXG5leHBvcnQgZGVmYXVsdCBzZXR1cFxuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL2luZGV4LmpzIl0sInNvdXJjZVJvb3QiOiIifQ==