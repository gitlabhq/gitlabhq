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
/******/ 	return __webpack_require__(__webpack_require__.s = 14);
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

exports.DATA_TRIGGER = DATA_TRIGGER;
exports.DATA_DROPDOWN = DATA_DROPDOWN;
exports.SELECTED_CLASS = SELECTED_CLASS;
exports.ACTIVE_CLASS = ACTIVE_CLASS;

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

var _dropdown = __webpack_require__(9);

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
    return target.hasAttribute(_constants.DATA_TRIGGER) || target.hasAttribute(_constants.DATA_DROPDOWN);
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

__webpack_require__(1);

var _hook_button = __webpack_require__(10);

var _hook_button2 = _interopRequireDefault(_hook_button);

var _hook_input = __webpack_require__(11);

var _hook_input2 = _interopRequireDefault(_hook_input);

var _utils = __webpack_require__(3);

var _utils2 = _interopRequireDefault(_utils);

var _keyboard = __webpack_require__(12);

var _keyboard2 = _interopRequireDefault(_keyboard);

var _constants = __webpack_require__(0);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DropLab = function DropLab() {
  this.ready = false;
  this.hooks = [];
  this.queuedData = [];
  this.config = {};

  this.eventWrapper = {};
};

Object.assign(DropLab.prototype, {
  loadStatic: function loadStatic() {
    var dropdownTriggers = [].slice.apply(document.querySelectorAll('[' + _constants.DATA_TRIGGER + ']'));
    this.addHooks(dropdownTriggers);
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
      availableList = document.querySelector(hook.dataset[_utils2.default.toCamelCase(_constants.DATA_TRIGGER)]);
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

  init: function init(hook, list, plugins, config) {
    var _this3 = this;

    hook ? this.addHook(hook, list, plugins, config) : this.loadStatic();

    this.addEvents();

    (0, _keyboard2.default)();

    this.fireReady();

    this.queuedData.forEach(function (data) {
      return _this3.addData(data);
    });
    this.queuedData = [];

    return this;
  }
});

exports.default = DropLab;

/***/ }),
/* 5 */,
/* 6 */,
/* 7 */,
/* 8 */,
/* 9 */
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
    selected.classList.add(_constants.SELECTED_CLASS);
  },

  removeSelectedClasses: function removeSelectedClasses() {
    var items = this.items || this.getItems();

    items.forEach(function (item) {
      return item.classList.remove(_constants.SELECTED_CLASS);
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
/* 10 */
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
/* 11 */
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
/* 12 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _constants = __webpack_require__(0);

var Keyboard = function Keyboard() {
  var currentKey;
  var currentFocus;
  var isUpArrow = false;
  var isDownArrow = false;
  var removeHighlight = function removeHighlight(list) {
    var itemElements = Array.prototype.slice.call(list.list.querySelectorAll('li:not(.divider)'), 0);
    var listItems = [];
    for (var i = 0; i < itemElements.length; i++) {
      var listItem = itemElements[i];
      listItem.classList.remove(_constants.ACTIVE_CLASS);

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
        el.classList.add(_constants.ACTIVE_CLASS);

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

exports.default = Keyboard;

/***/ }),
/* 13 */,
/* 14 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _droplab = __webpack_require__(4);

Object.keys(_droplab).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _droplab[key];
    }
  });
});

/***/ })
/******/ ]);
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAgOTMzZmY3ZDVlZDM5M2RjNjNiY2EiLCJ3ZWJwYWNrOi8vLy4vc3JjL2NvbnN0YW50cy5qcyIsIndlYnBhY2s6Ly8vLi9+L2N1c3RvbS1ldmVudC1wb2x5ZmlsbC9jdXN0b20tZXZlbnQtcG9seWZpbGwuanMiLCJ3ZWJwYWNrOi8vLy4vc3JjL2hvb2suanMiLCJ3ZWJwYWNrOi8vLy4vc3JjL3V0aWxzLmpzIiwid2VicGFjazovLy8uL3NyYy9kcm9wbGFiLmpzIiwid2VicGFjazovLy8uL3NyYy9kcm9wZG93bi5qcyIsIndlYnBhY2s6Ly8vLi9zcmMvaG9va19idXR0b24uanMiLCJ3ZWJwYWNrOi8vLy4vc3JjL2hvb2tfaW5wdXQuanMiLCJ3ZWJwYWNrOi8vLy4vc3JjL2tleWJvYXJkLmpzIiwid2VicGFjazovLy8uL3NyYy9pbmRleC5qcyJdLCJuYW1lcyI6WyJEQVRBX1RSSUdHRVIiLCJEQVRBX0RST1BET1dOIiwiU0VMRUNURURfQ0xBU1MiLCJBQ1RJVkVfQ0xBU1MiLCJIb29rIiwidHJpZ2dlciIsImxpc3QiLCJwbHVnaW5zIiwiY29uZmlnIiwidHlwZSIsImV2ZW50IiwiaWQiLCJPYmplY3QiLCJhc3NpZ24iLCJwcm90b3R5cGUiLCJhZGRFdmVudHMiLCJjb25zdHJ1Y3RvciIsInV0aWxzIiwidG9DYW1lbENhc2UiLCJhdHRyIiwiY2FtZWxpemUiLCJzcGxpdCIsInNsaWNlIiwiam9pbiIsInQiLCJzIiwiZCIsInAiLCJoYXNPd25Qcm9wZXJ0eSIsImNhbGwiLCJyZXBsYWNlIiwiUmVnRXhwIiwic3RyIiwibGV0dGVyIiwiaW5kZXgiLCJ0b0xvd2VyQ2FzZSIsInRvVXBwZXJDYXNlIiwiY2xvc2VzdCIsInRoaXNUYWciLCJzdG9wVGFnIiwidGFnTmFtZSIsInBhcmVudE5vZGUiLCJpc0Ryb3BEb3duUGFydHMiLCJ0YXJnZXQiLCJoYXNBdHRyaWJ1dGUiLCJEcm9wTGFiIiwicmVhZHkiLCJob29rcyIsInF1ZXVlZERhdGEiLCJldmVudFdyYXBwZXIiLCJsb2FkU3RhdGljIiwiZHJvcGRvd25UcmlnZ2VycyIsImFwcGx5IiwiZG9jdW1lbnQiLCJxdWVyeVNlbGVjdG9yQWxsIiwiYWRkSG9va3MiLCJhZGREYXRhIiwiYXJncyIsImFyZ3VtZW50cyIsImFwcGx5QXJncyIsInNldERhdGEiLCJkZXN0cm95IiwiZm9yRWFjaCIsImhvb2siLCJyZW1vdmVFdmVudHMiLCJtZXRob2ROYW1lIiwicHVzaCIsIl9hZGREYXRhIiwiZGF0YSIsIl9wcm9jZXNzRGF0YSIsIl9zZXREYXRhIiwiQXJyYXkiLCJpc0FycmF5IiwiZG9jdW1lbnRDbGlja2VkIiwiYmluZCIsImFkZEV2ZW50TGlzdGVuZXIiLCJlIiwiaGlkZSIsInJlbW92ZUV2ZW50TGlzdGVuZXIiLCJjaGFuZ2VIb29rTGlzdCIsImF2YWlsYWJsZVRyaWdnZXIiLCJnZXRFbGVtZW50QnlJZCIsImkiLCJkYXRhc2V0IiwiZHJvcGRvd25BY3RpdmUiLCJzcGxpY2UiLCJhZGRIb29rIiwiYXZhaWxhYmxlSG9vayIsInF1ZXJ5U2VsZWN0b3IiLCJhdmFpbGFibGVMaXN0IiwiRWxlbWVudCIsIkhvb2tPYmplY3QiLCJzZXRDb25maWciLCJvYmoiLCJmaXJlUmVhZHkiLCJyZWFkeUV2ZW50IiwiQ3VzdG9tRXZlbnQiLCJkZXRhaWwiLCJkcm9wZG93biIsImRpc3BhdGNoRXZlbnQiLCJpbml0IiwiRHJvcERvd24iLCJjdXJyZW50SW5kZXgiLCJoaWRkZW4iLCJpdGVtcyIsImdldEl0ZW1zIiwiaW5pdFRlbXBsYXRlU3RyaW5nIiwiaW5pdGlhbFN0YXRlIiwiaW5uZXJIVE1MIiwidGVtcGxhdGVTdHJpbmciLCJsZW5ndGgiLCJvdXRlckhUTUwiLCJjbGlja0V2ZW50Iiwic2VsZWN0ZWQiLCJhZGRTZWxlY3RlZENsYXNzIiwicHJldmVudERlZmF1bHQiLCJsaXN0RXZlbnQiLCJyZW1vdmVTZWxlY3RlZENsYXNzZXMiLCJjbGFzc0xpc3QiLCJhZGQiLCJpdGVtIiwicmVtb3ZlIiwidG9nZ2xlIiwic2hvdyIsInJlbmRlciIsImNvbmNhdCIsImNoaWxkcmVuIiwibWFwIiwicmVuZGVyQ2hpbGRyZW4iLCJyZW5kZXJhYmxlTGlzdCIsImh0bWwiLCJ0ZW1wbGF0ZSIsImNyZWF0ZUVsZW1lbnQiLCJzZXRJbWFnZXNTcmMiLCJmaXJzdENoaWxkIiwic3R5bGUiLCJkaXNwbGF5IiwiZHJvcGxhYl9oaWRkZW4iLCJpbWFnZXMiLCJpbWFnZSIsInNyYyIsImdldEF0dHJpYnV0ZSIsInJlbW92ZUF0dHJpYnV0ZSIsIkhvb2tCdXR0b24iLCJhZGRQbHVnaW5zIiwiY3JlYXRlIiwicGx1Z2luIiwiY2xpY2tlZCIsImJ1dHRvbkV2ZW50IiwiYnViYmxlcyIsImNhbmNlbGFibGUiLCJyZXN0b3JlSW5pdGlhbFN0YXRlIiwicmVtb3ZlUGx1Z2lucyIsIkhvb2tJbnB1dCIsIm1vdXNlZG93biIsImlucHV0Iiwia2V5dXAiLCJrZXlkb3duIiwiaGFzUmVtb3ZlZEV2ZW50cyIsImlucHV0RXZlbnQiLCJ0ZXh0IiwidmFsdWUiLCJtb3VzZUV2ZW50Iiwia2V5RXZlbnQiLCJldmVudE5hbWUiLCJ3aGljaCIsImtleSIsIktleWJvYXJkIiwiY3VycmVudEtleSIsImN1cnJlbnRGb2N1cyIsImlzVXBBcnJvdyIsImlzRG93bkFycm93IiwicmVtb3ZlSGlnaGxpZ2h0IiwiaXRlbUVsZW1lbnRzIiwibGlzdEl0ZW1zIiwibGlzdEl0ZW0iLCJzZXRNZW51Rm9yQXJyb3dzIiwiZWwiLCJmaWx0ZXJEcm9wZG93bkVsIiwiZmlsdGVyRHJvcGRvd25Cb3R0b20iLCJvZmZzZXRIZWlnaHQiLCJlbE9mZnNldFRvcCIsIm9mZnNldFRvcCIsInNjcm9sbFRvcCIsInNlbGVjdEl0ZW0iLCJjdXJyZW50SXRlbSIsInR5cGVkT24iXSwibWFwcGluZ3MiOiI7QUFBQTtBQUNBOztBQUVBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0E7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RXFCLE1BQUYsQ0FBU2xDLElBQVQsQ0FBY3pELElBQS9CO0FBQ0QsR0FyQ0Q7O0FBdUNBK0MsV0FBU3NCLGdCQUFULENBQTBCLGNBQTFCLEVBQTBDK0UsU0FBMUM7QUFDQXJHLFdBQVNzQixnQkFBVCxDQUEwQixZQUExQixFQUF3Q2tGLE9BQXhDO0FBQ0QsQ0ExR0Q7O2tCQTRHZVUsUTs7Ozs7Ozs7Ozs7Ozs7OztBQzlHZjtBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQUEsRyIsImZpbGUiOiIuL2Rpc3QvZHJvcGxhYi5qcyIsInNvdXJjZXNDb250ZW50IjpbIiBcdC8vIFRoZSBtb2R1bGUgY2FjaGVcbiBcdHZhciBpbnN0YWxsZWRNb2R1bGVzID0ge307XG5cbiBcdC8vIFRoZSByZXF1aXJlIGZ1bmN0aW9uXG4gXHRmdW5jdGlvbiBfX3dlYnBhY2tfcmVxdWlyZV9fKG1vZHVsZUlkKSB7XG5cbiBcdFx0Ly8gQ2hlY2sgaWYgbW9kdWxlIGlzIGluIGNhY2hlXG4gXHRcdGlmKGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdKVxuIFx0XHRcdHJldHVybiBpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXS5leHBvcnRzO1xuXG4gXHRcdC8vIENyZWF0ZSBhIG5ldyBtb2R1bGUgKGFuZCBwdXQgaXQgaW50byB0aGUgY2FjaGUpXG4gXHRcdHZhciBtb2R1bGUgPSBpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXSA9IHtcbiBcdFx0XHRpOiBtb2R1bGVJZCxcbiBcdFx0XHRsOiBmYWxzZSxcbiBcdFx0XHRleHBvcnRzOiB7fVxuIFx0XHR9O1xuXG4gXHRcdC8vIEV4ZWN1dGUgdGhlIG1vZHVsZSBmdW5jdGlvblxuIFx0XHRtb2R1bGVzW21vZHVsZUlkXS5jYWxsKG1vZHVsZS5leHBvcnRzLCBtb2R1bGUsIG1vZHVsZS5leHBvcnRzLCBfX3dlYnBhY2tfcmVxdWlyZV9fKTtcblxuIFx0XHQvLyBGbGFnIHRoZSBtb2R1bGUgYXMgbG9hZGVkXG4gXHRcdG1vZHVsZS5sID0gdHJ1ZTtcblxuIFx0XHQvLyBSZXR1cm4gdGhlIGV4cG9ydHMgb2YgdGhlIG1vZHVsZVxuIFx0XHRyZXR1cm4gbW9kdWxlLmV4cG9ydHM7XG4gXHR9XG5cblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGVzIG9iamVjdCAoX193ZWJwYWNrX21vZHVsZXNfXylcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubSA9IG1vZHVsZXM7XG5cbiBcdC8vIGV4cG9zZSB0aGUgbW9kdWxlIGNhY2hlXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmMgPSBpbnN0YWxsZWRNb2R1bGVzO1xuXG4gXHQvLyBpZGVudGl0eSBmdW5jdGlvbiBmb3IgY2FsbGluZyBoYXJtb255IGltcG9ydHMgd2l0aCB0aGUgY29ycmVjdCBjb250ZXh0XG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmkgPSBmdW5jdGlvbih2YWx1ZSkgeyByZXR1cm4gdmFsdWU7IH07XG5cbiBcdC8vIGRlZmluZSBnZXR0ZXIgZnVuY3Rpb24gZm9yIGhhcm1vbnkgZXhwb3J0c1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5kID0gZnVuY3Rpb24oZXhwb3J0cywgbmFtZSwgZ2V0dGVyKSB7XG4gXHRcdGlmKCFfX3dlYnBhY2tfcmVxdWlyZV9fLm8oZXhwb3J0cywgbmFtZSkpIHtcbiBcdFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgbmFtZSwge1xuIFx0XHRcdFx0Y29uZmlndXJhYmxlOiBmYWxzZSxcbiBcdFx0XHRcdGVudW1lcmFibGU6IHRydWUsXG4gXHRcdFx0XHRnZXQ6IGdldHRlclxuIFx0XHRcdH0pO1xuIFx0XHR9XG4gXHR9O1xuXG4gXHQvLyBnZXREZWZhdWx0RXhwb3J0IGZ1bmN0aW9uIGZvciBjb21wYXRpYmlsaXR5IHdpdGggbm9uLWhhcm1vbnkgbW9kdWxlc1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5uID0gZnVuY3Rpb24obW9kdWxlKSB7XG4gXHRcdHZhciBnZXR0ZXIgPSBtb2R1bGUgJiYgbW9kdWxlLl9fZXNNb2R1bGUgP1xuIFx0XHRcdGZ1bmN0aW9uIGdldERlZmF1bHQoKSB7IHJldHVybiBtb2R1bGVbJ2RlZmF1bHQnXTsgfSA6XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0TW9kdWxlRXhwb3J0cygpIHsgcmV0dXJuIG1vZHVsZTsgfTtcbiBcdFx0X193ZWJwYWNrX3JlcXVpcmVfXy5kKGdldHRlciwgJ2EnLCBnZXR0ZXIpO1xuIFx0XHRyZXR1cm4gZ2V0dGVyO1xuIFx0fTtcblxuIFx0Ly8gT2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm8gPSBmdW5jdGlvbihvYmplY3QsIHByb3BlcnR5KSB7IHJldHVybiBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwob2JqZWN0LCBwcm9wZXJ0eSk7IH07XG5cbiBcdC8vIF9fd2VicGFja19wdWJsaWNfcGF0aF9fXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLnAgPSBcIlwiO1xuXG4gXHQvLyBMb2FkIGVudHJ5IG1vZHVsZSBhbmQgcmV0dXJuIGV4cG9ydHNcbiBcdHJldHVybiBfX3dlYnBhY2tfcmVxdWlyZV9fKF9fd2VicGFja19yZXF1aXJlX18ucyA9IDE0KTtcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyB3ZWJwYWNrL2Jvb3RzdHJhcCA5MzNmZjdkNWVkMzkzZGM2M2JjYSIsImNvbnN0IERBVEFfVFJJR0dFUiA9ICdkYXRhLWRyb3Bkb3duLXRyaWdnZXInO1xuY29uc3QgREFUQV9EUk9QRE9XTiA9ICdkYXRhLWRyb3Bkb3duJztcbmNvbnN0IFNFTEVDVEVEX0NMQVNTID0gJ2Ryb3BsYWItaXRlbS1zZWxlY3RlZCc7XG5jb25zdCBBQ1RJVkVfQ0xBU1MgPSAnZHJvcGxhYi1pdGVtLWFjdGl2ZSc7XG5cbmV4cG9ydCB7XG4gIERBVEFfVFJJR0dFUixcbiAgREFUQV9EUk9QRE9XTixcbiAgU0VMRUNURURfQ0xBU1MsXG4gIEFDVElWRV9DTEFTUyxcbn07XG5cblxuXG4vLyBXRUJQQUNLIEZPT1RFUiAvL1xuLy8gLi9zcmMvY29uc3RhbnRzLmpzIiwiLy8gUG9seWZpbGwgZm9yIGNyZWF0aW5nIEN1c3RvbUV2ZW50cyBvbiBJRTkvMTAvMTFcblxuLy8gY29kZSBwdWxsZWQgZnJvbTpcbi8vIGh0dHBzOi8vZ2l0aHViLmNvbS9kNHRvY2NoaW5pL2N1c3RvbWV2ZW50LXBvbHlmaWxsXG4vLyBodHRwczovL2RldmVsb3Blci5tb3ppbGxhLm9yZy9lbi1VUy9kb2NzL1dlYi9BUEkvQ3VzdG9tRXZlbnQjUG9seWZpbGxcblxudHJ5IHtcbiAgICB2YXIgY2UgPSBuZXcgd2luZG93LkN1c3RvbUV2ZW50KCd0ZXN0Jyk7XG4gICAgY2UucHJldmVudERlZmF1bHQoKTtcbiAgICBpZiAoY2UuZGVmYXVsdFByZXZlbnRlZCAhPT0gdHJ1ZSkge1xuICAgICAgICAvLyBJRSBoYXMgcHJvYmxlbXMgd2l0aCAucHJldmVudERlZmF1bHQoKSBvbiBjdXN0b20gZXZlbnRzXG4gICAgICAgIC8vIGh0dHA6Ly9zdGFja292ZXJmbG93LmNvbS9xdWVzdGlvbnMvMjMzNDkxOTFcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdDb3VsZCBub3QgcHJldmVudCBkZWZhdWx0Jyk7XG4gICAgfVxufSBjYXRjaChlKSB7XG4gIHZhciBDdXN0b21FdmVudCA9IGZ1bmN0aW9uKGV2ZW50LCBwYXJhbXMpIHtcbiAgICB2YXIgZXZ0LCBvcmlnUHJldmVudDtcbiAgICBwYXJhbXMgPSBwYXJhbXMgfHwge1xuICAgICAgYnViYmxlczogZmFsc2UsXG4gICAgICBjYW5jZWxhYmxlOiBmYWxzZSxcbiAgICAgIGRldGFpbDogdW5kZWZpbmVkXG4gICAgfTtcblxuICAgIGV2dCA9IGRvY3VtZW50LmNyZWF0ZUV2ZW50KFwiQ3VzdG9tRXZlbnRcIik7XG4gICAgZXZ0LmluaXRDdXN0b21FdmVudChldmVudCwgcGFyYW1zLmJ1YmJsZXMsIHBhcmFtcy5jYW5jZWxhYmxlLCBwYXJhbXMuZGV0YWlsKTtcbiAgICBvcmlnUHJldmVudCA9IGV2dC5wcmV2ZW50RGVmYXVsdDtcbiAgICBldnQucHJldmVudERlZmF1bHQgPSBmdW5jdGlvbiAoKSB7XG4gICAgICBvcmlnUHJldmVudC5jYWxsKHRoaXMpO1xuICAgICAgdHJ5IHtcbiAgICAgICAgT2JqZWN0LmRlZmluZVByb3BlcnR5KHRoaXMsICdkZWZhdWx0UHJldmVudGVkJywge1xuICAgICAgICAgIGdldDogZnVuY3Rpb24gKCkge1xuICAgICAgICAgICAgcmV0dXJuIHRydWU7XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICAgIH0gY2F0Y2goZSkge1xuICAgICAgICB0aGlzLmRlZmF1bHRQcmV2ZW50ZWQgPSB0cnVlO1xuICAgICAgfVxuICAgIH07XG4gICAgcmV0dXJuIGV2dDtcbiAgfTtcblxuICBDdXN0b21FdmVudC5wcm90b3R5cGUgPSB3aW5kb3cuRXZlbnQucHJvdG90eXBlO1xuICB3aW5kb3cuQ3VzdG9tRXZlbnQgPSBDdXN0b21FdmVudDsgLy8gZXhwb3NlIGRlZmluaXRpb24gdG8gd2luZG93XG59XG5cblxuXG4vLy8vLy8vLy8vLy8vLy8vLy9cbi8vIFdFQlBBQ0sgRk9PVEVSXG4vLyAuL34vY3VzdG9tLWV2ZW50LXBvbHlmaWxsL2N1c3RvbS1ldmVudC1wb2x5ZmlsbC5qc1xuLy8gbW9kdWxlIGlkID0gMVxuLy8gbW9kdWxlIGNodW5rcyA9IDAgMSIsImltcG9ydCBEcm9wRG93biBmcm9tICcuL2Ryb3Bkb3duJztcblxudmFyIEhvb2sgPSBmdW5jdGlvbih0cmlnZ2VyLCBsaXN0LCBwbHVnaW5zLCBjb25maWcpe1xuICB0aGlzLnRyaWdnZXIgPSB0cmlnZ2VyO1xuICB0aGlzLmxpc3QgPSBuZXcgRHJvcERvd24obGlzdCk7XG4gIHRoaXMudHlwZSA9ICdIb29rJztcbiAgdGhpcy5ldmVudCA9ICdjbGljayc7XG4gIHRoaXMucGx1Z2lucyA9IHBsdWdpbnMgfHwgW107XG4gIHRoaXMuY29uZmlnID0gY29uZmlnIHx8IHt9O1xuICB0aGlzLmlkID0gdHJpZ2dlci5pZDtcbn07XG5cbk9iamVjdC5hc3NpZ24oSG9vay5wcm90b3R5cGUsIHtcblxuICBhZGRFdmVudHM6IGZ1bmN0aW9uKCl7fSxcblxuICBjb25zdHJ1Y3RvcjogSG9vayxcbn0pO1xuXG5leHBvcnQgZGVmYXVsdCBIb29rO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL2hvb2suanMiLCJpbXBvcnQgeyBEQVRBX1RSSUdHRVIsIERBVEFfRFJPUERPV04gfSBmcm9tICcuL2NvbnN0YW50cyc7XG5cbmNvbnN0IHV0aWxzID0ge1xuICB0b0NhbWVsQ2FzZShhdHRyKSB7XG4gICAgcmV0dXJuIHRoaXMuY2FtZWxpemUoYXR0ci5zcGxpdCgnLScpLnNsaWNlKDEpLmpvaW4oJyAnKSk7XG4gIH0sXG5cbiAgdChzLCBkKSB7XG4gICAgZm9yIChjb25zdCBwIGluIGQpIHtcbiAgICAgIGlmIChPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwoZCwgcCkpIHtcbiAgICAgICAgcyA9IHMucmVwbGFjZShuZXcgUmVnRXhwKGB7eyR7cH19fWAsICdnJyksIGRbcF0pO1xuICAgICAgfVxuICAgIH1cbiAgICByZXR1cm4gcztcbiAgfSxcblxuICBjYW1lbGl6ZShzdHIpIHtcbiAgICByZXR1cm4gc3RyLnJlcGxhY2UoLyg/Ol5cXHd8W0EtWl18XFxiXFx3KS9nLCAobGV0dGVyLCBpbmRleCkgPT4ge1xuICAgICAgcmV0dXJuIGluZGV4ID09PSAwID8gbGV0dGVyLnRvTG93ZXJDYXNlKCkgOiBsZXR0ZXIudG9VcHBlckNhc2UoKTtcbiAgICB9KS5yZXBsYWNlKC9cXHMrL2csICcnKTtcbiAgfSxcblxuICBjbG9zZXN0KHRoaXNUYWcsIHN0b3BUYWcpIHtcbiAgICB3aGlsZSAodGhpc1RhZyAmJiB0aGlzVGFnLnRhZ05hbWUgIT09IHN0b3BUYWcgJiYgdGhpc1RhZy50YWdOYW1lICE9PSAnSFRNTCcpIHtcbiAgICAgIHRoaXNUYWcgPSB0aGlzVGFnLnBhcmVudE5vZGU7XG4gICAgfVxuICAgIHJldHVybiB0aGlzVGFnO1xuICB9LFxuXG4gIGlzRHJvcERvd25QYXJ0cyh0YXJnZXQpIHtcbiAgICBpZiAoIXRhcmdldCB8fCB0YXJnZXQudGFnTmFtZSA9PT0gJ0hUTUwnKSByZXR1cm4gZmFsc2U7XG4gICAgcmV0dXJuIHRhcmdldC5oYXNBdHRyaWJ1dGUoREFUQV9UUklHR0VSKSB8fCB0YXJnZXQuaGFzQXR0cmlidXRlKERBVEFfRFJPUERPV04pO1xuICB9LFxufTtcblxuXG5leHBvcnQgZGVmYXVsdCB1dGlscztcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyAuL3NyYy91dGlscy5qcyIsImltcG9ydCAnY3VzdG9tLWV2ZW50LXBvbHlmaWxsJztcbmltcG9ydCBIb29rQnV0dG9uIGZyb20gJy4vaG9va19idXR0b24nO1xuaW1wb3J0IEhvb2tJbnB1dCBmcm9tICcuL2hvb2tfaW5wdXQnO1xuaW1wb3J0IHV0aWxzIGZyb20gJy4vdXRpbHMnO1xuaW1wb3J0IEtleWJvYXJkIGZyb20gJy4va2V5Ym9hcmQnO1xuaW1wb3J0IHsgREFUQV9UUklHR0VSIH0gZnJvbSAnLi9jb25zdGFudHMnO1xuXG52YXIgRHJvcExhYiA9IGZ1bmN0aW9uKCkge1xuICB0aGlzLnJlYWR5ID0gZmFsc2U7XG4gIHRoaXMuaG9va3MgPSBbXTtcbiAgdGhpcy5xdWV1ZWREYXRhID0gW107XG4gIHRoaXMuY29uZmlnID0ge307XG5cbiAgdGhpcy5ldmVudFdyYXBwZXIgPSB7fTtcbn07XG5cbk9iamVjdC5hc3NpZ24oRHJvcExhYi5wcm90b3R5cGUsIHtcbiAgbG9hZFN0YXRpYzogZnVuY3Rpb24oKXtcbiAgICB2YXIgZHJvcGRvd25UcmlnZ2VycyA9IFtdLnNsaWNlLmFwcGx5KGRvY3VtZW50LnF1ZXJ5U2VsZWN0b3JBbGwoYFske0RBVEFfVFJJR0dFUn1dYCkpO1xuICAgIHRoaXMuYWRkSG9va3MoZHJvcGRvd25UcmlnZ2Vycyk7XG4gIH0sXG5cbiAgYWRkRGF0YTogZnVuY3Rpb24gKCkge1xuICAgIHZhciBhcmdzID0gW10uc2xpY2UuYXBwbHkoYXJndW1lbnRzKTtcbiAgICB0aGlzLmFwcGx5QXJncyhhcmdzLCAnX2FkZERhdGEnKTtcbiAgfSxcblxuICBzZXREYXRhOiBmdW5jdGlvbigpIHtcbiAgICB2YXIgYXJncyA9IFtdLnNsaWNlLmFwcGx5KGFyZ3VtZW50cyk7XG4gICAgdGhpcy5hcHBseUFyZ3MoYXJncywgJ19zZXREYXRhJyk7XG4gIH0sXG5cbiAgZGVzdHJveTogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5ob29rcy5mb3JFYWNoKGhvb2sgPT4gaG9vay5kZXN0cm95KCkpO1xuICAgIHRoaXMuaG9va3MgPSBbXTtcbiAgICB0aGlzLnJlbW92ZUV2ZW50cygpO1xuICB9LFxuXG4gIGFwcGx5QXJnczogZnVuY3Rpb24oYXJncywgbWV0aG9kTmFtZSkge1xuICAgIGlmICh0aGlzLnJlYWR5KSByZXR1cm4gdGhpc1ttZXRob2ROYW1lXS5hcHBseSh0aGlzLCBhcmdzKTtcblxuICAgIHRoaXMucXVldWVkRGF0YSA9IHRoaXMucXVldWVkRGF0YSB8fCBbXTtcbiAgICB0aGlzLnF1ZXVlZERhdGEucHVzaChhcmdzKTtcbiAgfSxcblxuICBfYWRkRGF0YTogZnVuY3Rpb24odHJpZ2dlciwgZGF0YSkge1xuICAgIHRoaXMuX3Byb2Nlc3NEYXRhKHRyaWdnZXIsIGRhdGEsICdhZGREYXRhJyk7XG4gIH0sXG5cbiAgX3NldERhdGE6IGZ1bmN0aW9uKHRyaWdnZXIsIGRhdGEpIHtcbiAgICB0aGlzLl9wcm9jZXNzRGF0YSh0cmlnZ2VyLCBkYXRhLCAnc2V0RGF0YScpO1xuICB9LFxuXG4gIF9wcm9jZXNzRGF0YTogZnVuY3Rpb24odHJpZ2dlciwgZGF0YSwgbWV0aG9kTmFtZSkge1xuICAgIHRoaXMuaG9va3MuZm9yRWFjaCgoaG9vaykgPT4ge1xuICAgICAgaWYgKEFycmF5LmlzQXJyYXkodHJpZ2dlcikpIGhvb2subGlzdFttZXRob2ROYW1lXSh0cmlnZ2VyKTtcblxuICAgICAgaWYgKGhvb2sudHJpZ2dlci5pZCA9PT0gdHJpZ2dlcikgaG9vay5saXN0W21ldGhvZE5hbWVdKGRhdGEpO1xuICAgIH0pO1xuICB9LFxuXG4gIGFkZEV2ZW50czogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5ldmVudFdyYXBwZXIuZG9jdW1lbnRDbGlja2VkID0gdGhpcy5kb2N1bWVudENsaWNrZWQuYmluZCh0aGlzKVxuICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ2NsaWNrJywgdGhpcy5ldmVudFdyYXBwZXIuZG9jdW1lbnRDbGlja2VkKTtcbiAgfSxcblxuICBkb2N1bWVudENsaWNrZWQ6IGZ1bmN0aW9uKGUpIHtcbiAgICBsZXQgdGhpc1RhZyA9IGUudGFyZ2V0O1xuXG4gICAgaWYgKHRoaXNUYWcudGFnTmFtZSAhPT0gJ1VMJykgdGhpc1RhZyA9IHV0aWxzLmNsb3Nlc3QodGhpc1RhZywgJ1VMJyk7XG4gICAgaWYgKHV0aWxzLmlzRHJvcERvd25QYXJ0cyh0aGlzVGFnLCB0aGlzLmhvb2tzKSB8fCB1dGlscy5pc0Ryb3BEb3duUGFydHMoZS50YXJnZXQsIHRoaXMuaG9va3MpKSByZXR1cm47XG5cbiAgICB0aGlzLmhvb2tzLmZvckVhY2goaG9vayA9PiBob29rLmxpc3QuaGlkZSgpKTtcbiAgfSxcblxuICByZW1vdmVFdmVudHM6IGZ1bmN0aW9uKCl7XG4gICAgZG9jdW1lbnQucmVtb3ZlRXZlbnRMaXN0ZW5lcignY2xpY2snLCB0aGlzLmV2ZW50V3JhcHBlci5kb2N1bWVudENsaWNrZWQpO1xuICB9LFxuXG4gIGNoYW5nZUhvb2tMaXN0OiBmdW5jdGlvbih0cmlnZ2VyLCBsaXN0LCBwbHVnaW5zLCBjb25maWcpIHtcbiAgICBjb25zdCBhdmFpbGFibGVUcmlnZ2VyID0gIHR5cGVvZiB0cmlnZ2VyID09PSAnc3RyaW5nJyA/IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKHRyaWdnZXIpIDogdHJpZ2dlcjtcblxuXG4gICAgdGhpcy5ob29rcy5mb3JFYWNoKChob29rLCBpKSA9PiB7XG4gICAgICBob29rLmxpc3QubGlzdC5kYXRhc2V0LmRyb3Bkb3duQWN0aXZlID0gZmFsc2U7XG5cbiAgICAgIGlmIChob29rLnRyaWdnZXIgIT09IGF2YWlsYWJsZVRyaWdnZXIpIHJldHVybjtcblxuICAgICAgaG9vay5kZXN0cm95KCk7XG4gICAgICB0aGlzLmhvb2tzLnNwbGljZShpLCAxKTtcbiAgICAgIHRoaXMuYWRkSG9vayhhdmFpbGFibGVUcmlnZ2VyLCBsaXN0LCBwbHVnaW5zLCBjb25maWcpO1xuICAgIH0pO1xuICB9LFxuXG4gIGFkZEhvb2s6IGZ1bmN0aW9uKGhvb2ssIGxpc3QsIHBsdWdpbnMsIGNvbmZpZykge1xuICAgIGNvbnN0IGF2YWlsYWJsZUhvb2sgPSB0eXBlb2YgaG9vayA9PT0gJ3N0cmluZycgPyBkb2N1bWVudC5xdWVyeVNlbGVjdG9yKGhvb2spIDogaG9vaztcbiAgICBsZXQgYXZhaWxhYmxlTGlzdDtcblxuICAgIGlmICh0eXBlb2YgbGlzdCA9PT0gJ3N0cmluZycpIHtcbiAgICAgIGF2YWlsYWJsZUxpc3QgPSBkb2N1bWVudC5xdWVyeVNlbGVjdG9yKGxpc3QpO1xuICAgIH0gZWxzZSBpZiAobGlzdCBpbnN0YW5jZW9mIEVsZW1lbnQpIHtcbiAgICAgIGF2YWlsYWJsZUxpc3QgPSBsaXN0O1xuICAgIH0gZWxzZSB7XG4gICAgICBhdmFpbGFibGVMaXN0ID0gZG9jdW1lbnQucXVlcnlTZWxlY3Rvcihob29rLmRhdGFzZXRbdXRpbHMudG9DYW1lbENhc2UoREFUQV9UUklHR0VSKV0pO1xuICAgIH1cblxuICAgIGF2YWlsYWJsZUxpc3QuZGF0YXNldC5kcm9wZG93bkFjdGl2ZSA9IHRydWU7XG5cbiAgICBjb25zdCBIb29rT2JqZWN0ID0gYXZhaWxhYmxlSG9vay50YWdOYW1lID09PSAnSU5QVVQnID8gSG9va0lucHV0IDogSG9va0J1dHRvbjtcbiAgICB0aGlzLmhvb2tzLnB1c2gobmV3IEhvb2tPYmplY3QoYXZhaWxhYmxlSG9vaywgYXZhaWxhYmxlTGlzdCwgcGx1Z2lucywgY29uZmlnKSk7XG5cbiAgICByZXR1cm4gdGhpcztcbiAgfSxcblxuICBhZGRIb29rczogZnVuY3Rpb24oaG9va3MsIHBsdWdpbnMsIGNvbmZpZykge1xuICAgIGhvb2tzLmZvckVhY2goaG9vayA9PiB0aGlzLmFkZEhvb2soaG9vaywgbnVsbCwgcGx1Z2lucywgY29uZmlnKSk7XG4gICAgcmV0dXJuIHRoaXM7XG4gIH0sXG5cbiAgc2V0Q29uZmlnOiBmdW5jdGlvbihvYmope1xuICAgIHRoaXMuY29uZmlnID0gb2JqO1xuICB9LFxuXG4gIGZpcmVSZWFkeTogZnVuY3Rpb24oKSB7XG4gICAgY29uc3QgcmVhZHlFdmVudCA9IG5ldyBDdXN0b21FdmVudCgncmVhZHkuZGwnLCB7XG4gICAgICBkZXRhaWw6IHtcbiAgICAgICAgZHJvcGRvd246IHRoaXMsXG4gICAgICB9LFxuICAgIH0pO1xuICAgIGRvY3VtZW50LmRpc3BhdGNoRXZlbnQocmVhZHlFdmVudCk7XG5cbiAgICB0aGlzLnJlYWR5ID0gdHJ1ZTtcbiAgfSxcblxuICBpbml0OiBmdW5jdGlvbiAoaG9vaywgbGlzdCwgcGx1Z2lucywgY29uZmlnKSB7XG4gICAgaG9vayA/IHRoaXMuYWRkSG9vayhob29rLCBsaXN0LCBwbHVnaW5zLCBjb25maWcpIDogdGhpcy5sb2FkU3RhdGljKCk7XG5cbiAgICB0aGlzLmFkZEV2ZW50cygpO1xuXG4gICAgS2V5Ym9hcmQoKTtcblxuICAgIHRoaXMuZmlyZVJlYWR5KCk7XG5cbiAgICB0aGlzLnF1ZXVlZERhdGEuZm9yRWFjaChkYXRhID0+IHRoaXMuYWRkRGF0YShkYXRhKSk7XG4gICAgdGhpcy5xdWV1ZWREYXRhID0gW107XG5cbiAgICByZXR1cm4gdGhpcztcbiAgfSxcbn0pO1xuXG5leHBvcnQgZGVmYXVsdCBEcm9wTGFiO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL2Ryb3BsYWIuanMiLCJpbXBvcnQgJ2N1c3RvbS1ldmVudC1wb2x5ZmlsbCc7XG5pbXBvcnQgdXRpbHMgZnJvbSAnLi91dGlscyc7XG5pbXBvcnQgeyBTRUxFQ1RFRF9DTEFTUyB9IGZyb20gJy4uL3NyYy9jb25zdGFudHMnO1xuXG52YXIgRHJvcERvd24gPSBmdW5jdGlvbihsaXN0KSB7XG4gIHRoaXMuY3VycmVudEluZGV4ID0gMDtcbiAgdGhpcy5oaWRkZW4gPSB0cnVlO1xuICB0aGlzLmxpc3QgPSB0eXBlb2YgbGlzdCA9PT0gJ3N0cmluZycgPyBkb2N1bWVudC5xdWVyeVNlbGVjdG9yKGxpc3QpIDogbGlzdDtcbiAgdGhpcy5pdGVtcyA9IFtdO1xuXG4gIHRoaXMuZXZlbnRXcmFwcGVyID0ge307XG5cbiAgdGhpcy5nZXRJdGVtcygpO1xuICB0aGlzLmluaXRUZW1wbGF0ZVN0cmluZygpO1xuICB0aGlzLmFkZEV2ZW50cygpO1xuXG4gIHRoaXMuaW5pdGlhbFN0YXRlID0gbGlzdC5pbm5lckhUTUw7XG59O1xuXG5PYmplY3QuYXNzaWduKERyb3BEb3duLnByb3RvdHlwZSwge1xuICBnZXRJdGVtczogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5pdGVtcyA9IFtdLnNsaWNlLmNhbGwodGhpcy5saXN0LnF1ZXJ5U2VsZWN0b3JBbGwoJ2xpJykpO1xuICAgIHJldHVybiB0aGlzLml0ZW1zO1xuICB9LFxuXG4gIGluaXRUZW1wbGF0ZVN0cmluZzogZnVuY3Rpb24oKSB7XG4gICAgdmFyIGl0ZW1zID0gdGhpcy5pdGVtcyB8fCB0aGlzLmdldEl0ZW1zKCk7XG5cbiAgICB2YXIgdGVtcGxhdGVTdHJpbmcgPSAnJztcbiAgICBpZiAoaXRlbXMubGVuZ3RoID4gMCkgdGVtcGxhdGVTdHJpbmcgPSBpdGVtc1tpdGVtcy5sZW5ndGggLSAxXS5vdXRlckhUTUw7XG4gICAgdGhpcy50ZW1wbGF0ZVN0cmluZyA9IHRlbXBsYXRlU3RyaW5nO1xuXG4gICAgcmV0dXJuIHRoaXMudGVtcGxhdGVTdHJpbmc7XG4gIH0sXG5cbiAgY2xpY2tFdmVudDogZnVuY3Rpb24oZSkge1xuICAgIHZhciBzZWxlY3RlZCA9IHV0aWxzLmNsb3Nlc3QoZS50YXJnZXQsICdMSScpO1xuICAgIGlmICghc2VsZWN0ZWQpIHJldHVybjtcblxuICAgIHRoaXMuYWRkU2VsZWN0ZWRDbGFzcyhzZWxlY3RlZCk7XG5cbiAgICBlLnByZXZlbnREZWZhdWx0KCk7XG4gICAgdGhpcy5oaWRlKCk7XG5cbiAgICB2YXIgbGlzdEV2ZW50ID0gbmV3IEN1c3RvbUV2ZW50KCdjbGljay5kbCcsIHtcbiAgICAgIGRldGFpbDoge1xuICAgICAgICBsaXN0OiB0aGlzLFxuICAgICAgICBzZWxlY3RlZDogc2VsZWN0ZWQsXG4gICAgICAgIGRhdGE6IGUudGFyZ2V0LmRhdGFzZXQsXG4gICAgICB9LFxuICAgIH0pO1xuICAgIHRoaXMubGlzdC5kaXNwYXRjaEV2ZW50KGxpc3RFdmVudCk7XG4gIH0sXG5cbiAgYWRkU2VsZWN0ZWRDbGFzczogZnVuY3Rpb24gKHNlbGVjdGVkKSB7XG4gICAgdGhpcy5yZW1vdmVTZWxlY3RlZENsYXNzZXMoKTtcbiAgICBzZWxlY3RlZC5jbGFzc0xpc3QuYWRkKFNFTEVDVEVEX0NMQVNTKTtcbiAgfSxcblxuICByZW1vdmVTZWxlY3RlZENsYXNzZXM6IGZ1bmN0aW9uICgpIHtcbiAgICBjb25zdCBpdGVtcyA9IHRoaXMuaXRlbXMgfHwgdGhpcy5nZXRJdGVtcygpO1xuXG4gICAgaXRlbXMuZm9yRWFjaChpdGVtID0+IGl0ZW0uY2xhc3NMaXN0LnJlbW92ZShTRUxFQ1RFRF9DTEFTUykpO1xuICB9LFxuXG4gIGFkZEV2ZW50czogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5ldmVudFdyYXBwZXIuY2xpY2tFdmVudCA9IHRoaXMuY2xpY2tFdmVudC5iaW5kKHRoaXMpXG4gICAgdGhpcy5saXN0LmFkZEV2ZW50TGlzdGVuZXIoJ2NsaWNrJywgdGhpcy5ldmVudFdyYXBwZXIuY2xpY2tFdmVudCk7XG4gIH0sXG5cbiAgdG9nZ2xlOiBmdW5jdGlvbigpIHtcbiAgICB0aGlzLmhpZGRlbiA/IHRoaXMuc2hvdygpIDogdGhpcy5oaWRlKCk7XG4gIH0sXG5cbiAgc2V0RGF0YTogZnVuY3Rpb24oZGF0YSkge1xuICAgIHRoaXMuZGF0YSA9IGRhdGE7XG4gICAgdGhpcy5yZW5kZXIoZGF0YSk7XG4gIH0sXG5cbiAgYWRkRGF0YTogZnVuY3Rpb24oZGF0YSkge1xuICAgIHRoaXMuZGF0YSA9ICh0aGlzLmRhdGEgfHwgW10pLmNvbmNhdChkYXRhKTtcbiAgICB0aGlzLnJlbmRlcih0aGlzLmRhdGEpO1xuICB9LFxuXG4gIHJlbmRlcjogZnVuY3Rpb24oZGF0YSkge1xuICAgIGNvbnN0IGNoaWxkcmVuID0gZGF0YSA/IGRhdGEubWFwKHRoaXMucmVuZGVyQ2hpbGRyZW4uYmluZCh0aGlzKSkgOiBbXTtcbiAgICBjb25zdCByZW5kZXJhYmxlTGlzdCA9IHRoaXMubGlzdC5xdWVyeVNlbGVjdG9yKCd1bFtkYXRhLWR5bmFtaWNdJykgfHwgdGhpcy5saXN0O1xuXG4gICAgcmVuZGVyYWJsZUxpc3QuaW5uZXJIVE1MID0gY2hpbGRyZW4uam9pbignJyk7XG4gIH0sXG5cbiAgcmVuZGVyQ2hpbGRyZW46IGZ1bmN0aW9uKGRhdGEpIHtcbiAgICB2YXIgaHRtbCA9IHV0aWxzLnQodGhpcy50ZW1wbGF0ZVN0cmluZywgZGF0YSk7XG4gICAgdmFyIHRlbXBsYXRlID0gZG9jdW1lbnQuY3JlYXRlRWxlbWVudCgnZGl2Jyk7XG5cbiAgICB0ZW1wbGF0ZS5pbm5lckhUTUwgPSBodG1sO1xuICAgIHRoaXMuc2V0SW1hZ2VzU3JjKHRlbXBsYXRlKTtcbiAgICB0ZW1wbGF0ZS5maXJzdENoaWxkLnN0eWxlLmRpc3BsYXkgPSBkYXRhLmRyb3BsYWJfaGlkZGVuID8gJ25vbmUnIDogJ2Jsb2NrJztcblxuICAgIHJldHVybiB0ZW1wbGF0ZS5maXJzdENoaWxkLm91dGVySFRNTDtcbiAgfSxcblxuICBzZXRJbWFnZXNTcmM6IGZ1bmN0aW9uKHRlbXBsYXRlKSB7XG4gICAgY29uc3QgaW1hZ2VzID0gW10uc2xpY2UuY2FsbCh0ZW1wbGF0ZS5xdWVyeVNlbGVjdG9yQWxsKCdpbWdbZGF0YS1zcmNdJykpO1xuXG4gICAgaW1hZ2VzLmZvckVhY2goKGltYWdlKSA9PiB7XG4gICAgICBpbWFnZS5zcmMgPSBpbWFnZS5nZXRBdHRyaWJ1dGUoJ2RhdGEtc3JjJyk7XG4gICAgICBpbWFnZS5yZW1vdmVBdHRyaWJ1dGUoJ2RhdGEtc3JjJyk7XG4gICAgfSk7XG4gIH0sXG5cbiAgc2hvdzogZnVuY3Rpb24oKSB7XG4gICAgaWYgKCF0aGlzLmhpZGRlbikgcmV0dXJuO1xuICAgIHRoaXMubGlzdC5zdHlsZS5kaXNwbGF5ID0gJ2Jsb2NrJztcbiAgICB0aGlzLmN1cnJlbnRJbmRleCA9IDA7XG4gICAgdGhpcy5oaWRkZW4gPSBmYWxzZTtcbiAgfSxcblxuICBoaWRlOiBmdW5jdGlvbigpIHtcbiAgICBpZiAodGhpcy5oaWRkZW4pIHJldHVybjtcbiAgICB0aGlzLmxpc3Quc3R5bGUuZGlzcGxheSA9ICdub25lJztcbiAgICB0aGlzLmN1cnJlbnRJbmRleCA9IDA7XG4gICAgdGhpcy5oaWRkZW4gPSB0cnVlO1xuICB9LFxuXG4gIHRvZ2dsZTogZnVuY3Rpb24gKCkge1xuICAgIHRoaXMuaGlkZGVuID8gdGhpcy5zaG93KCkgOiB0aGlzLmhpZGUoKTtcbiAgfSxcblxuICBkZXN0cm95OiBmdW5jdGlvbigpIHtcbiAgICB0aGlzLmhpZGUoKTtcbiAgICB0aGlzLmxpc3QucmVtb3ZlRXZlbnRMaXN0ZW5lcignY2xpY2snLCB0aGlzLmV2ZW50V3JhcHBlci5jbGlja0V2ZW50KTtcbiAgfVxufSk7XG5cbmV4cG9ydCBkZWZhdWx0IERyb3BEb3duO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL2Ryb3Bkb3duLmpzIiwiaW1wb3J0ICdjdXN0b20tZXZlbnQtcG9seWZpbGwnO1xuaW1wb3J0IEhvb2sgZnJvbSAnLi9ob29rJztcblxudmFyIEhvb2tCdXR0b24gPSBmdW5jdGlvbih0cmlnZ2VyLCBsaXN0LCBwbHVnaW5zLCBjb25maWcpIHtcbiAgSG9vay5jYWxsKHRoaXMsIHRyaWdnZXIsIGxpc3QsIHBsdWdpbnMsIGNvbmZpZyk7XG5cbiAgdGhpcy50eXBlID0gJ2J1dHRvbic7XG4gIHRoaXMuZXZlbnQgPSAnY2xpY2snO1xuXG4gIHRoaXMuZXZlbnRXcmFwcGVyID0ge307XG5cbiAgdGhpcy5hZGRFdmVudHMoKTtcbiAgdGhpcy5hZGRQbHVnaW5zKCk7XG59O1xuXG5Ib29rQnV0dG9uLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoSG9vay5wcm90b3R5cGUpO1xuXG5PYmplY3QuYXNzaWduKEhvb2tCdXR0b24ucHJvdG90eXBlLCB7XG4gIGFkZFBsdWdpbnM6IGZ1bmN0aW9uKCkge1xuICAgIHRoaXMucGx1Z2lucy5mb3JFYWNoKHBsdWdpbiA9PiBwbHVnaW4uaW5pdCh0aGlzKSk7XG4gIH0sXG5cbiAgY2xpY2tlZDogZnVuY3Rpb24oZSl7XG4gICAgdmFyIGJ1dHRvbkV2ZW50ID0gbmV3IEN1c3RvbUV2ZW50KCdjbGljay5kbCcsIHtcbiAgICAgIGRldGFpbDoge1xuICAgICAgICBob29rOiB0aGlzLFxuICAgICAgfSxcbiAgICAgIGJ1YmJsZXM6IHRydWUsXG4gICAgICBjYW5jZWxhYmxlOiB0cnVlXG4gICAgfSk7XG4gICAgZS50YXJnZXQuZGlzcGF0Y2hFdmVudChidXR0b25FdmVudCk7XG5cbiAgICB0aGlzLmxpc3QudG9nZ2xlKCk7XG4gIH0sXG5cbiAgYWRkRXZlbnRzOiBmdW5jdGlvbigpe1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLmNsaWNrZWQgPSB0aGlzLmNsaWNrZWQuYmluZCh0aGlzKTtcbiAgICB0aGlzLnRyaWdnZXIuYWRkRXZlbnRMaXN0ZW5lcignY2xpY2snLCB0aGlzLmV2ZW50V3JhcHBlci5jbGlja2VkKTtcbiAgfSxcblxuICByZW1vdmVFdmVudHM6IGZ1bmN0aW9uKCl7XG4gICAgdGhpcy50cmlnZ2VyLnJlbW92ZUV2ZW50TGlzdGVuZXIoJ2NsaWNrJywgdGhpcy5ldmVudFdyYXBwZXIuY2xpY2tlZCk7XG4gIH0sXG5cbiAgcmVzdG9yZUluaXRpYWxTdGF0ZTogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5saXN0Lmxpc3QuaW5uZXJIVE1MID0gdGhpcy5saXN0LmluaXRpYWxTdGF0ZTtcbiAgfSxcblxuICByZW1vdmVQbHVnaW5zOiBmdW5jdGlvbigpIHtcbiAgICB0aGlzLnBsdWdpbnMuZm9yRWFjaChwbHVnaW4gPT4gcGx1Z2luLmRlc3Ryb3koKSk7XG4gIH0sXG5cbiAgZGVzdHJveTogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5yZXN0b3JlSW5pdGlhbFN0YXRlKCk7XG5cbiAgICB0aGlzLnJlbW92ZUV2ZW50cygpO1xuICAgIHRoaXMucmVtb3ZlUGx1Z2lucygpO1xuICB9LFxuXG4gIGNvbnN0cnVjdG9yOiBIb29rQnV0dG9uLFxufSk7XG5cblxuZXhwb3J0IGRlZmF1bHQgSG9va0J1dHRvbjtcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyAuL3NyYy9ob29rX2J1dHRvbi5qcyIsImltcG9ydCAnY3VzdG9tLWV2ZW50LXBvbHlmaWxsJztcbmltcG9ydCBIb29rIGZyb20gJy4vaG9vayc7XG5cbnZhciBIb29rSW5wdXQgPSBmdW5jdGlvbih0cmlnZ2VyLCBsaXN0LCBwbHVnaW5zLCBjb25maWcpIHtcbiAgSG9vay5jYWxsKHRoaXMsIHRyaWdnZXIsIGxpc3QsIHBsdWdpbnMsIGNvbmZpZyk7XG5cbiAgdGhpcy50eXBlID0gJ2lucHV0JztcbiAgdGhpcy5ldmVudCA9ICdpbnB1dCc7XG5cbiAgdGhpcy5ldmVudFdyYXBwZXIgPSB7fTtcblxuICB0aGlzLmFkZEV2ZW50cygpO1xuICB0aGlzLmFkZFBsdWdpbnMoKTtcbn07XG5cbk9iamVjdC5hc3NpZ24oSG9va0lucHV0LnByb3RvdHlwZSwge1xuICBhZGRQbHVnaW5zOiBmdW5jdGlvbigpIHtcbiAgICB0aGlzLnBsdWdpbnMuZm9yRWFjaChwbHVnaW4gPT4gcGx1Z2luLmluaXQodGhpcykpO1xuICB9LFxuXG4gIGFkZEV2ZW50czogZnVuY3Rpb24oKXtcbiAgICB0aGlzLmV2ZW50V3JhcHBlci5tb3VzZWRvd24gPSB0aGlzLm1vdXNlZG93bi5iaW5kKHRoaXMpO1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLmlucHV0ID0gdGhpcy5pbnB1dC5iaW5kKHRoaXMpO1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLmtleXVwID0gdGhpcy5rZXl1cC5iaW5kKHRoaXMpO1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLmtleWRvd24gPSB0aGlzLmtleWRvd24uYmluZCh0aGlzKTtcblxuICAgIHRoaXMudHJpZ2dlci5hZGRFdmVudExpc3RlbmVyKCdtb3VzZWRvd24nLCB0aGlzLmV2ZW50V3JhcHBlci5tb3VzZWRvd24pO1xuICAgIHRoaXMudHJpZ2dlci5hZGRFdmVudExpc3RlbmVyKCdpbnB1dCcsIHRoaXMuZXZlbnRXcmFwcGVyLmlucHV0KTtcbiAgICB0aGlzLnRyaWdnZXIuYWRkRXZlbnRMaXN0ZW5lcigna2V5dXAnLCB0aGlzLmV2ZW50V3JhcHBlci5rZXl1cCk7XG4gICAgdGhpcy50cmlnZ2VyLmFkZEV2ZW50TGlzdGVuZXIoJ2tleWRvd24nLCB0aGlzLmV2ZW50V3JhcHBlci5rZXlkb3duKTtcbiAgfSxcblxuICByZW1vdmVFdmVudHM6IGZ1bmN0aW9uKCkge1xuICAgIHRoaXMuaGFzUmVtb3ZlZEV2ZW50cyA9IHRydWU7XG5cbiAgICB0aGlzLnRyaWdnZXIucmVtb3ZlRXZlbnRMaXN0ZW5lcignbW91c2Vkb3duJywgdGhpcy5ldmVudFdyYXBwZXIubW91c2Vkb3duKTtcbiAgICB0aGlzLnRyaWdnZXIucmVtb3ZlRXZlbnRMaXN0ZW5lcignaW5wdXQnLCB0aGlzLmV2ZW50V3JhcHBlci5pbnB1dCk7XG4gICAgdGhpcy50cmlnZ2VyLnJlbW92ZUV2ZW50TGlzdGVuZXIoJ2tleXVwJywgdGhpcy5ldmVudFdyYXBwZXIua2V5dXApO1xuICAgIHRoaXMudHJpZ2dlci5yZW1vdmVFdmVudExpc3RlbmVyKCdrZXlkb3duJywgdGhpcy5ldmVudFdyYXBwZXIua2V5ZG93bik7XG4gIH0sXG5cbiAgaW5wdXQ6IGZ1bmN0aW9uKGUpIHtcbiAgICBpZih0aGlzLmhhc1JlbW92ZWRFdmVudHMpIHJldHVybjtcblxuICAgIHRoaXMubGlzdC5zaG93KCk7XG5cbiAgICBjb25zdCBpbnB1dEV2ZW50ID0gbmV3IEN1c3RvbUV2ZW50KCdpbnB1dC5kbCcsIHtcbiAgICAgIGRldGFpbDoge1xuICAgICAgICBob29rOiB0aGlzLFxuICAgICAgICB0ZXh0OiBlLnRhcmdldC52YWx1ZSxcbiAgICAgIH0sXG4gICAgICBidWJibGVzOiB0cnVlLFxuICAgICAgY2FuY2VsYWJsZTogdHJ1ZVxuICAgIH0pO1xuICAgIGUudGFyZ2V0LmRpc3BhdGNoRXZlbnQoaW5wdXRFdmVudCk7XG4gIH0sXG5cbiAgbW91c2Vkb3duOiBmdW5jdGlvbihlKSB7XG4gICAgaWYgKHRoaXMuaGFzUmVtb3ZlZEV2ZW50cykgcmV0dXJuO1xuXG4gICAgY29uc3QgbW91c2VFdmVudCA9IG5ldyBDdXN0b21FdmVudCgnbW91c2Vkb3duLmRsJywge1xuICAgICAgZGV0YWlsOiB7XG4gICAgICAgIGhvb2s6IHRoaXMsXG4gICAgICAgIHRleHQ6IGUudGFyZ2V0LnZhbHVlLFxuICAgICAgfSxcbiAgICAgIGJ1YmJsZXM6IHRydWUsXG4gICAgICBjYW5jZWxhYmxlOiB0cnVlLFxuICAgIH0pO1xuICAgIGUudGFyZ2V0LmRpc3BhdGNoRXZlbnQobW91c2VFdmVudCk7XG4gIH0sXG5cbiAga2V5dXA6IGZ1bmN0aW9uKGUpIHtcbiAgICBpZiAodGhpcy5oYXNSZW1vdmVkRXZlbnRzKSByZXR1cm47XG5cbiAgICB0aGlzLmtleUV2ZW50KGUsICdrZXl1cC5kbCcpO1xuICB9LFxuXG4gIGtleWRvd246IGZ1bmN0aW9uKGUpIHtcbiAgICBpZiAodGhpcy5oYXNSZW1vdmVkRXZlbnRzKSByZXR1cm47XG5cbiAgICB0aGlzLmtleUV2ZW50KGUsICdrZXlkb3duLmRsJyk7XG4gIH0sXG5cbiAga2V5RXZlbnQ6IGZ1bmN0aW9uKGUsIGV2ZW50TmFtZSkge1xuICAgIHRoaXMubGlzdC5zaG93KCk7XG5cbiAgICBjb25zdCBrZXlFdmVudCA9IG5ldyBDdXN0b21FdmVudChldmVudE5hbWUsIHtcbiAgICAgIGRldGFpbDoge1xuICAgICAgICBob29rOiB0aGlzLFxuICAgICAgICB0ZXh0OiBlLnRhcmdldC52YWx1ZSxcbiAgICAgICAgd2hpY2g6IGUud2hpY2gsXG4gICAgICAgIGtleTogZS5rZXksXG4gICAgICB9LFxuICAgICAgYnViYmxlczogdHJ1ZSxcbiAgICAgIGNhbmNlbGFibGU6IHRydWUsXG4gICAgfSk7XG4gICAgZS50YXJnZXQuZGlzcGF0Y2hFdmVudChrZXlFdmVudCk7XG4gIH0sXG5cbiAgcmVzdG9yZUluaXRpYWxTdGF0ZTogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5saXN0Lmxpc3QuaW5uZXJIVE1MID0gdGhpcy5saXN0LmluaXRpYWxTdGF0ZTtcbiAgfSxcblxuICByZW1vdmVQbHVnaW5zOiBmdW5jdGlvbigpIHtcbiAgICB0aGlzLnBsdWdpbnMuZm9yRWFjaChwbHVnaW4gPT4gcGx1Z2luLmRlc3Ryb3koKSk7XG4gIH0sXG5cbiAgZGVzdHJveTogZnVuY3Rpb24oKSB7XG4gICAgdGhpcy5yZXN0b3JlSW5pdGlhbFN0YXRlKCk7XG5cbiAgICB0aGlzLnJlbW92ZUV2ZW50cygpO1xuICAgIHRoaXMucmVtb3ZlUGx1Z2lucygpO1xuXG4gICAgdGhpcy5saXN0LmRlc3Ryb3koKTtcbiAgfVxufSk7XG5cbmV4cG9ydCBkZWZhdWx0IEhvb2tJbnB1dDtcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyAuL3NyYy9ob29rX2lucHV0LmpzIiwiaW1wb3J0IHsgQUNUSVZFX0NMQVNTIH0gZnJvbSAnLi9jb25zdGFudHMnO1xuXG5jb25zdCBLZXlib2FyZCA9IGZ1bmN0aW9uICgpIHtcbiAgdmFyIGN1cnJlbnRLZXk7XG4gIHZhciBjdXJyZW50Rm9jdXM7XG4gIHZhciBpc1VwQXJyb3cgPSBmYWxzZTtcbiAgdmFyIGlzRG93bkFycm93ID0gZmFsc2U7XG4gIHZhciByZW1vdmVIaWdobGlnaHQgPSBmdW5jdGlvbiByZW1vdmVIaWdobGlnaHQobGlzdCkge1xuICAgIHZhciBpdGVtRWxlbWVudHMgPSBBcnJheS5wcm90b3R5cGUuc2xpY2UuY2FsbChsaXN0Lmxpc3QucXVlcnlTZWxlY3RvckFsbCgnbGk6bm90KC5kaXZpZGVyKScpLCAwKTtcbiAgICB2YXIgbGlzdEl0ZW1zID0gW107XG4gICAgZm9yKHZhciBpID0gMDsgaSA8IGl0ZW1FbGVtZW50cy5sZW5ndGg7IGkrKykge1xuICAgICAgdmFyIGxpc3RJdGVtID0gaXRlbUVsZW1lbnRzW2ldO1xuICAgICAgbGlzdEl0ZW0uY2xhc3NMaXN0LnJlbW92ZShBQ1RJVkVfQ0xBU1MpO1xuXG4gICAgICBpZiAobGlzdEl0ZW0uc3R5bGUuZGlzcGxheSAhPT0gJ25vbmUnKSB7XG4gICAgICAgIGxpc3RJdGVtcy5wdXNoKGxpc3RJdGVtKTtcbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIGxpc3RJdGVtcztcbiAgfTtcblxuICB2YXIgc2V0TWVudUZvckFycm93cyA9IGZ1bmN0aW9uIHNldE1lbnVGb3JBcnJvd3MobGlzdCkge1xuICAgIHZhciBsaXN0SXRlbXMgPSByZW1vdmVIaWdobGlnaHQobGlzdCk7XG4gICAgaWYobGlzdC5jdXJyZW50SW5kZXg+MCl7XG4gICAgICBpZighbGlzdEl0ZW1zW2xpc3QuY3VycmVudEluZGV4LTFdKXtcbiAgICAgICAgbGlzdC5jdXJyZW50SW5kZXggPSBsaXN0LmN1cnJlbnRJbmRleC0xO1xuICAgICAgfVxuXG4gICAgICBpZiAobGlzdEl0ZW1zW2xpc3QuY3VycmVudEluZGV4LTFdKSB7XG4gICAgICAgIHZhciBlbCA9IGxpc3RJdGVtc1tsaXN0LmN1cnJlbnRJbmRleC0xXTtcbiAgICAgICAgdmFyIGZpbHRlckRyb3Bkb3duRWwgPSBlbC5jbG9zZXN0KCcuZmlsdGVyLWRyb3Bkb3duJyk7XG4gICAgICAgIGVsLmNsYXNzTGlzdC5hZGQoQUNUSVZFX0NMQVNTKTtcblxuICAgICAgICBpZiAoZmlsdGVyRHJvcGRvd25FbCkge1xuICAgICAgICAgIHZhciBmaWx0ZXJEcm9wZG93bkJvdHRvbSA9IGZpbHRlckRyb3Bkb3duRWwub2Zmc2V0SGVpZ2h0O1xuICAgICAgICAgIHZhciBlbE9mZnNldFRvcCA9IGVsLm9mZnNldFRvcCAtIDMwO1xuXG4gICAgICAgICAgaWYgKGVsT2Zmc2V0VG9wID4gZmlsdGVyRHJvcGRvd25Cb3R0b20pIHtcbiAgICAgICAgICAgIGZpbHRlckRyb3Bkb3duRWwuc2Nyb2xsVG9wID0gZWxPZmZzZXRUb3AgLSBmaWx0ZXJEcm9wZG93bkJvdHRvbTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gIH07XG5cbiAgdmFyIG1vdXNlZG93biA9IGZ1bmN0aW9uIG1vdXNlZG93bihlKSB7XG4gICAgdmFyIGxpc3QgPSBlLmRldGFpbC5ob29rLmxpc3Q7XG4gICAgcmVtb3ZlSGlnaGxpZ2h0KGxpc3QpO1xuICAgIGxpc3Quc2hvdygpO1xuICAgIGxpc3QuY3VycmVudEluZGV4ID0gMDtcbiAgICBpc1VwQXJyb3cgPSBmYWxzZTtcbiAgICBpc0Rvd25BcnJvdyA9IGZhbHNlO1xuICB9O1xuICB2YXIgc2VsZWN0SXRlbSA9IGZ1bmN0aW9uIHNlbGVjdEl0ZW0obGlzdCkge1xuICAgIHZhciBsaXN0SXRlbXMgPSByZW1vdmVIaWdobGlnaHQobGlzdCk7XG4gICAgdmFyIGN1cnJlbnRJdGVtID0gbGlzdEl0ZW1zW2xpc3QuY3VycmVudEluZGV4LTFdO1xuICAgIHZhciBsaXN0RXZlbnQgPSBuZXcgQ3VzdG9tRXZlbnQoJ2NsaWNrLmRsJywge1xuICAgICAgZGV0YWlsOiB7XG4gICAgICAgIGxpc3Q6IGxpc3QsXG4gICAgICAgIHNlbGVjdGVkOiBjdXJyZW50SXRlbSxcbiAgICAgICAgZGF0YTogY3VycmVudEl0ZW0uZGF0YXNldCxcbiAgICAgIH0sXG4gICAgfSk7XG4gICAgbGlzdC5saXN0LmRpc3BhdGNoRXZlbnQobGlzdEV2ZW50KTtcbiAgICBsaXN0LmhpZGUoKTtcbiAgfVxuXG4gIHZhciBrZXlkb3duID0gZnVuY3Rpb24ga2V5ZG93bihlKXtcbiAgICB2YXIgdHlwZWRPbiA9IGUudGFyZ2V0O1xuICAgIHZhciBsaXN0ID0gZS5kZXRhaWwuaG9vay5saXN0O1xuICAgIHZhciBjdXJyZW50SW5kZXggPSBsaXN0LmN1cnJlbnRJbmRleDtcbiAgICBpc1VwQXJyb3cgPSBmYWxzZTtcbiAgICBpc0Rvd25BcnJvdyA9IGZhbHNlO1xuXG4gICAgaWYoZS5kZXRhaWwud2hpY2gpe1xuICAgICAgY3VycmVudEtleSA9IGUuZGV0YWlsLndoaWNoO1xuICAgICAgaWYoY3VycmVudEtleSA9PT0gMTMpe1xuICAgICAgICBzZWxlY3RJdGVtKGUuZGV0YWlsLmhvb2subGlzdCk7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cbiAgICAgIGlmKGN1cnJlbnRLZXkgPT09IDM4KSB7XG4gICAgICAgIGlzVXBBcnJvdyA9IHRydWU7XG4gICAgICB9XG4gICAgICBpZihjdXJyZW50S2V5ID09PSA0MCkge1xuICAgICAgICBpc0Rvd25BcnJvdyA9IHRydWU7XG4gICAgICB9XG4gICAgfSBlbHNlIGlmKGUuZGV0YWlsLmtleSkge1xuICAgICAgY3VycmVudEtleSA9IGUuZGV0YWlsLmtleTtcbiAgICAgIGlmKGN1cnJlbnRLZXkgPT09ICdFbnRlcicpe1xuICAgICAgICBzZWxlY3RJdGVtKGUuZGV0YWlsLmhvb2subGlzdCk7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cbiAgICAgIGlmKGN1cnJlbnRLZXkgPT09ICdBcnJvd1VwJykge1xuICAgICAgICBpc1VwQXJyb3cgPSB0cnVlO1xuICAgICAgfVxuICAgICAgaWYoY3VycmVudEtleSA9PT0gJ0Fycm93RG93bicpIHtcbiAgICAgICAgaXNEb3duQXJyb3cgPSB0cnVlO1xuICAgICAgfVxuICAgIH1cbiAgICBpZihpc1VwQXJyb3cpeyBjdXJyZW50SW5kZXgtLTsgfVxuICAgIGlmKGlzRG93bkFycm93KXsgY3VycmVudEluZGV4Kys7IH1cbiAgICBpZihjdXJyZW50SW5kZXggPCAwKXsgY3VycmVudEluZGV4ID0gMDsgfVxuICAgIGxpc3QuY3VycmVudEluZGV4ID0gY3VycmVudEluZGV4O1xuICAgIHNldE1lbnVGb3JBcnJvd3MoZS5kZXRhaWwuaG9vay5saXN0KTtcbiAgfTtcblxuICBkb2N1bWVudC5hZGRFdmVudExpc3RlbmVyKCdtb3VzZWRvd24uZGwnLCBtb3VzZWRvd24pO1xuICBkb2N1bWVudC5hZGRFdmVudExpc3RlbmVyKCdrZXlkb3duLmRsJywga2V5ZG93bik7XG59O1xuXG5leHBvcnQgZGVmYXVsdCBLZXlib2FyZDtcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyAuL3NyYy9rZXlib2FyZC5qcyIsImV4cG9ydCAqIGZyb20gJy4vZHJvcGxhYic7XG5cblxuXG4vLyBXRUJQQUNLIEZPT1RFUiAvL1xuLy8gLi9zcmMvaW5kZXguanMiXSwic291cmNlUm9vdCI6IiJ9