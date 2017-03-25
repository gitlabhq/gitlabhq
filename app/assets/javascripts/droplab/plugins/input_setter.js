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
/******/ 	return __webpack_require__(__webpack_require__.s = 8);
/******/ })
/************************************************************************/
/******/ ({

/***/ 8:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var droplabInputSetter = {
  init: function init(hook) {
    this.hook = hook;
    this.config = hook.config.droplabInputSetter || (this.hook.config.droplabInputSetter = {});

    this.eventWrapper = {};

    this.addEvents();
  },
  addEvents: function addEvents() {
    this.eventWrapper.setInputs = this.setInputs.bind(this);
    this.hook.list.list.addEventListener('click.dl', this.eventWrapper.setInputs);
  },
  removeEvents: function removeEvents() {
    this.hook.list.list.removeEventListener('click.dl', this.eventWrapper.setInputs);
  },
  setInputs: function setInputs(e) {
    var _this = this;

    var selectedItem = e.detail.selected;

    if (!Array.isArray(this.config)) this.config = [this.config];

    this.config.forEach(function (config) {
      return _this.setInput(config, selectedItem);
    });
  },
  setInput: function setInput(config, selectedItem) {
    var input = config.input || this.hook.trigger;
    var newValue = selectedItem.getAttribute(config.valueAttribute);

    if (input.tagName === 'INPUT') {
      input.value = newValue;
    } else {
      input.textContent = newValue;
    }
  },
  destroy: function destroy() {
    this.removeEvents();
  }
};

exports.default = droplabInputSetter;

/***/ })

/******/ });
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAgOTMzZmY3ZDVlZDM5M2RjNjNiY2E/MGFiZioqKioqIiwid2VicGFjazovLy8uL3NyYy9wbHVnaW5zL2lucHV0X3NldHRlci9pbnB1dF9zZXR0ZXIuanM/NTY5NyJdLCJuYW1lcyI6WyJkcm9wbGFiSW5wdXRTZXR0ZXIiLCJpbml0IiwiaG9vayIsImNvbmZpZyIsImV2ZW50V3JhcHBlciIsImFkZEV2ZW50cyIsInNldElucHV0cyIsImJpbmQiLCJsaXN0IiwiYWRkRXZlbnRMaXN0ZW5lciIsInJlbW92ZUV2ZW50cyIsInJlbW92ZUV2ZW50TGlzdGVuZXIiLCJlIiwic2VsZWN0ZWRJdGVtIiwiZGV0YWlsIiwic2VsZWN0ZWQiLCJBcnJheSIsImlzQXJyYXkiLCJmb3JFYWNoIiwic2V0SW5wdXQiLCJpbnB1dCIsInRyaWdnZXIiLCJuZXdWYWx1ZSIsImdldEF0dHJpYnV0ZSIsInZhbHVlQXR0cmlidXRlIiwidGFnTmFtZSIsInZhbHVlIiwidGV4dENvbnRlbnQiLCJkZXN0cm95Il0sIm1hcHBpbmdzIjoiO0FBQUE7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTs7O0FBR0E7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0EsbURBQTJDLGNBQWM7O0FBRXpEO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsYUFBSztBQUNMO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0EsbUNBQTJCLDBCQUEwQixFQUFFO0FBQ3ZELHlDQUFpQyxlQUFlO0FBQ2hEO0FBQ0E7QUFDQTs7QUFFQTtBQUNBLDhEQUFzRCwrREFBK0Q7O0FBRXJIO0FBQ0E7O0FBRUE7QUFDQTs7Ozs7Ozs7Ozs7Ozs7QUNoRUEsSUFBTUEscUJBQXFCO0FBQ3pCQyxNQUR5QixnQkFDcEJDLElBRG9CLEVBQ2Q7QUFDVCxTQUFLQSxJQUFMLEdBQVlBLElBQVo7QUFDQSxTQUFLQyxNQUFMLEdBQWNELEtBQUtDLE1BQUwsQ0FBWUgsa0JBQVosS0FBbUMsS0FBS0UsSUFBTCxDQUFVQyxNQUFWLENBQWlCSCxrQkFBakIsR0FBc0MsRUFBekUsQ0FBZDs7QUFFQSxTQUFLSSxZQUFMLEdBQW9CLEVBQXBCOztBQUVBLFNBQUtDLFNBQUw7QUFDRCxHQVJ3QjtBQVV6QkEsV0FWeUIsdUJBVWI7QUFDVixTQUFLRCxZQUFMLENBQWtCRSxTQUFsQixHQUE4QixLQUFLQSxTQUFMLENBQWVDLElBQWYsQ0FBb0IsSUFBcEIsQ0FBOUI7QUFDQSxTQUFLTCxJQUFMLENBQVVNLElBQVYsQ0FBZUEsSUFBZixDQUFvQkMsZ0JBQXBCLENBQXFDLFVBQXJDLEVBQWlELEtBQUtMLFlBQUwsQ0FBa0JFLFNBQW5FO0FBQ0QsR0Fid0I7QUFlekJJLGNBZnlCLDBCQWVWO0FBQ2IsU0FBS1IsSUFBTCxDQUFVTSxJQUFWLENBQWVBLElBQWYsQ0FBb0JHLG1CQUFwQixDQUF3QyxVQUF4QyxFQUFvRCxLQUFLUCxZQUFMLENBQWtCRSxTQUF0RTtBQUNELEdBakJ3QjtBQW1CekJBLFdBbkJ5QixxQkFtQmZNLENBbkJlLEVBbUJaO0FBQUE7O0FBQ1gsUUFBTUMsZUFBZUQsRUFBRUUsTUFBRixDQUFTQyxRQUE5Qjs7QUFFQSxRQUFJLENBQUNDLE1BQU1DLE9BQU4sQ0FBYyxLQUFLZCxNQUFuQixDQUFMLEVBQWlDLEtBQUtBLE1BQUwsR0FBYyxDQUFDLEtBQUtBLE1BQU4sQ0FBZDs7QUFFakMsU0FBS0EsTUFBTCxDQUFZZSxPQUFaLENBQW9CO0FBQUEsYUFBVSxNQUFLQyxRQUFMLENBQWNoQixNQUFkLEVBQXNCVSxZQUF0QixDQUFWO0FBQUEsS0FBcEI7QUFDRCxHQXpCd0I7QUEyQnpCTSxVQTNCeUIsb0JBMkJoQmhCLE1BM0JnQixFQTJCUlUsWUEzQlEsRUEyQk07QUFDN0IsUUFBTU8sUUFBUWpCLE9BQU9pQixLQUFQLElBQWdCLEtBQUtsQixJQUFMLENBQVVtQixPQUF4QztBQUNBLFFBQU1DLFdBQVdULGFBQWFVLFlBQWIsQ0FBMEJwQixPQUFPcUIsY0FBakMsQ0FBakI7O0FBRUEsUUFBSUosTUFBTUssT0FBTixLQUFrQixPQUF0QixFQUErQjtBQUM3QkwsWUFBTU0sS0FBTixHQUFjSixRQUFkO0FBQ0QsS0FGRCxNQUVPO0FBQ0xGLFlBQU1PLFdBQU4sR0FBb0JMLFFBQXBCO0FBQ0Q7QUFDRixHQXBDd0I7QUFzQ3pCTSxTQXRDeUIscUJBc0NmO0FBQ1IsU0FBS2xCLFlBQUw7QUFDRDtBQXhDd0IsQ0FBM0I7O2tCQTJDZVYsa0IiLCJmaWxlIjoiLi9kaXN0L3BsdWdpbnMvaW5wdXRfc2V0dGVyLmpzIiwic291cmNlc0NvbnRlbnQiOlsiIFx0Ly8gVGhlIG1vZHVsZSBjYWNoZVxuIFx0dmFyIGluc3RhbGxlZE1vZHVsZXMgPSB7fTtcblxuIFx0Ly8gVGhlIHJlcXVpcmUgZnVuY3Rpb25cbiBcdGZ1bmN0aW9uIF9fd2VicGFja19yZXF1aXJlX18obW9kdWxlSWQpIHtcblxuIFx0XHQvLyBDaGVjayBpZiBtb2R1bGUgaXMgaW4gY2FjaGVcbiBcdFx0aWYoaW5zdGFsbGVkTW9kdWxlc1ttb2R1bGVJZF0pXG4gXHRcdFx0cmV0dXJuIGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdLmV4cG9ydHM7XG5cbiBcdFx0Ly8gQ3JlYXRlIGEgbmV3IG1vZHVsZSAoYW5kIHB1dCBpdCBpbnRvIHRoZSBjYWNoZSlcbiBcdFx0dmFyIG1vZHVsZSA9IGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdID0ge1xuIFx0XHRcdGk6IG1vZHVsZUlkLFxuIFx0XHRcdGw6IGZhbHNlLFxuIFx0XHRcdGV4cG9ydHM6IHt9XG4gXHRcdH07XG5cbiBcdFx0Ly8gRXhlY3V0ZSB0aGUgbW9kdWxlIGZ1bmN0aW9uXG4gXHRcdG1vZHVsZXNbbW9kdWxlSWRdLmNhbGwobW9kdWxlLmV4cG9ydHMsIG1vZHVsZSwgbW9kdWxlLmV4cG9ydHMsIF9fd2VicGFja19yZXF1aXJlX18pO1xuXG4gXHRcdC8vIEZsYWcgdGhlIG1vZHVsZSBhcyBsb2FkZWRcbiBcdFx0bW9kdWxlLmwgPSB0cnVlO1xuXG4gXHRcdC8vIFJldHVybiB0aGUgZXhwb3J0cyBvZiB0aGUgbW9kdWxlXG4gXHRcdHJldHVybiBtb2R1bGUuZXhwb3J0cztcbiBcdH1cblxuXG4gXHQvLyBleHBvc2UgdGhlIG1vZHVsZXMgb2JqZWN0IChfX3dlYnBhY2tfbW9kdWxlc19fKVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5tID0gbW9kdWxlcztcblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGUgY2FjaGVcbiBcdF9fd2VicGFja19yZXF1aXJlX18uYyA9IGluc3RhbGxlZE1vZHVsZXM7XG5cbiBcdC8vIGlkZW50aXR5IGZ1bmN0aW9uIGZvciBjYWxsaW5nIGhhcm1vbnkgaW1wb3J0cyB3aXRoIHRoZSBjb3JyZWN0IGNvbnRleHRcbiBcdF9fd2VicGFja19yZXF1aXJlX18uaSA9IGZ1bmN0aW9uKHZhbHVlKSB7IHJldHVybiB2YWx1ZTsgfTtcblxuIFx0Ly8gZGVmaW5lIGdldHRlciBmdW5jdGlvbiBmb3IgaGFybW9ueSBleHBvcnRzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQgPSBmdW5jdGlvbihleHBvcnRzLCBuYW1lLCBnZXR0ZXIpIHtcbiBcdFx0aWYoIV9fd2VicGFja19yZXF1aXJlX18ubyhleHBvcnRzLCBuYW1lKSkge1xuIFx0XHRcdE9iamVjdC5kZWZpbmVQcm9wZXJ0eShleHBvcnRzLCBuYW1lLCB7XG4gXHRcdFx0XHRjb25maWd1cmFibGU6IGZhbHNlLFxuIFx0XHRcdFx0ZW51bWVyYWJsZTogdHJ1ZSxcbiBcdFx0XHRcdGdldDogZ2V0dGVyXG4gXHRcdFx0fSk7XG4gXHRcdH1cbiBcdH07XG5cbiBcdC8vIGdldERlZmF1bHRFeHBvcnQgZnVuY3Rpb24gZm9yIGNvbXBhdGliaWxpdHkgd2l0aCBub24taGFybW9ueSBtb2R1bGVzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm4gPSBmdW5jdGlvbihtb2R1bGUpIHtcbiBcdFx0dmFyIGdldHRlciA9IG1vZHVsZSAmJiBtb2R1bGUuX19lc01vZHVsZSA/XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0RGVmYXVsdCgpIHsgcmV0dXJuIG1vZHVsZVsnZGVmYXVsdCddOyB9IDpcbiBcdFx0XHRmdW5jdGlvbiBnZXRNb2R1bGVFeHBvcnRzKCkgeyByZXR1cm4gbW9kdWxlOyB9O1xuIFx0XHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQoZ2V0dGVyLCAnYScsIGdldHRlcik7XG4gXHRcdHJldHVybiBnZXR0ZXI7XG4gXHR9O1xuXG4gXHQvLyBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGxcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubyA9IGZ1bmN0aW9uKG9iamVjdCwgcHJvcGVydHkpIHsgcmV0dXJuIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbChvYmplY3QsIHByb3BlcnR5KTsgfTtcblxuIFx0Ly8gX193ZWJwYWNrX3B1YmxpY19wYXRoX19cbiBcdF9fd2VicGFja19yZXF1aXJlX18ucCA9IFwiXCI7XG5cbiBcdC8vIExvYWQgZW50cnkgbW9kdWxlIGFuZCByZXR1cm4gZXhwb3J0c1xuIFx0cmV0dXJuIF9fd2VicGFja19yZXF1aXJlX18oX193ZWJwYWNrX3JlcXVpcmVfXy5zID0gOCk7XG5cblxuXG4vLyBXRUJQQUNLIEZPT1RFUiAvL1xuLy8gd2VicGFjay9ib290c3RyYXAgOTMzZmY3ZDVlZDM5M2RjNjNiY2EiLCJjb25zdCBkcm9wbGFiSW5wdXRTZXR0ZXIgPSB7XG4gIGluaXQoaG9vaykge1xuICAgIHRoaXMuaG9vayA9IGhvb2s7XG4gICAgdGhpcy5jb25maWcgPSBob29rLmNvbmZpZy5kcm9wbGFiSW5wdXRTZXR0ZXIgfHwgKHRoaXMuaG9vay5jb25maWcuZHJvcGxhYklucHV0U2V0dGVyID0ge30pO1xuXG4gICAgdGhpcy5ldmVudFdyYXBwZXIgPSB7fTtcblxuICAgIHRoaXMuYWRkRXZlbnRzKCk7XG4gIH0sXG5cbiAgYWRkRXZlbnRzKCkge1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLnNldElucHV0cyA9IHRoaXMuc2V0SW5wdXRzLmJpbmQodGhpcyk7XG4gICAgdGhpcy5ob29rLmxpc3QubGlzdC5hZGRFdmVudExpc3RlbmVyKCdjbGljay5kbCcsIHRoaXMuZXZlbnRXcmFwcGVyLnNldElucHV0cyk7XG4gIH0sXG5cbiAgcmVtb3ZlRXZlbnRzKCkge1xuICAgIHRoaXMuaG9vay5saXN0Lmxpc3QucmVtb3ZlRXZlbnRMaXN0ZW5lcignY2xpY2suZGwnLCB0aGlzLmV2ZW50V3JhcHBlci5zZXRJbnB1dHMpO1xuICB9LFxuXG4gIHNldElucHV0cyhlKSB7XG4gICAgY29uc3Qgc2VsZWN0ZWRJdGVtID0gZS5kZXRhaWwuc2VsZWN0ZWQ7XG5cbiAgICBpZiAoIUFycmF5LmlzQXJyYXkodGhpcy5jb25maWcpKSB0aGlzLmNvbmZpZyA9IFt0aGlzLmNvbmZpZ107XG5cbiAgICB0aGlzLmNvbmZpZy5mb3JFYWNoKGNvbmZpZyA9PiB0aGlzLnNldElucHV0KGNvbmZpZywgc2VsZWN0ZWRJdGVtKSk7XG4gIH0sXG5cbiAgc2V0SW5wdXQoY29uZmlnLCBzZWxlY3RlZEl0ZW0pIHtcbiAgICBjb25zdCBpbnB1dCA9IGNvbmZpZy5pbnB1dCB8fCB0aGlzLmhvb2sudHJpZ2dlcjtcbiAgICBjb25zdCBuZXdWYWx1ZSA9IHNlbGVjdGVkSXRlbS5nZXRBdHRyaWJ1dGUoY29uZmlnLnZhbHVlQXR0cmlidXRlKTtcblxuICAgIGlmIChpbnB1dC50YWdOYW1lID09PSAnSU5QVVQnKSB7XG4gICAgICBpbnB1dC52YWx1ZSA9IG5ld1ZhbHVlO1xuICAgIH0gZWxzZSB7XG4gICAgICBpbnB1dC50ZXh0Q29udGVudCA9IG5ld1ZhbHVlO1xuICAgIH1cbiAgfSxcblxuICBkZXN0cm95KCkge1xuICAgIHRoaXMucmVtb3ZlRXZlbnRzKCk7XG4gIH0sXG59O1xuXG5leHBvcnQgZGVmYXVsdCBkcm9wbGFiSW5wdXRTZXR0ZXI7XG5cblxuXG4vLyBXRUJQQUNLIEZPT1RFUiAvL1xuLy8gLi9zcmMvcGx1Z2lucy9pbnB1dF9zZXR0ZXIvaW5wdXRfc2V0dGVyLmpzIl0sInNvdXJjZVJvb3QiOiIifQ==