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
/******/ 	return __webpack_require__(__webpack_require__.s = 13);
/******/ })
/************************************************************************/
/******/ ({

/***/ 13:
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
    var newValue = selectedItem.getAttribute(config.valueAttribute) || selectedItem.textContent;

    input.value = newValue;
  },
  destroy: function destroy() {
    this.removeEvents();
  }
};

window.droplabInputSetter = droplabInputSetter;

exports.default = droplabInputSetter;

/***/ })

/******/ });
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAgYTVmZGU1NjJhOGRjY2M3ZTliMTk/MWJhMSIsIndlYnBhY2s6Ly8vLi9zcmMvcGx1Z2lucy9pbnB1dF9zZXR0ZXIuanMiXSwibmFtZXMiOlsiZHJvcGxhYklucHV0U2V0dGVyIiwiaW5pdCIsImhvb2siLCJjb25maWciLCJldmVudFdyYXBwZXIiLCJhZGRFdmVudHMiLCJzZXRJbnB1dHMiLCJiaW5kIiwibGlzdCIsImFkZEV2ZW50TGlzdGVuZXIiLCJyZW1vdmVFdmVudHMiLCJyZW1vdmVFdmVudExpc3RlbmVyIiwiZSIsInNlbGVjdGVkSXRlbSIsImRldGFpbCIsInNlbGVjdGVkIiwiQXJyYXkiLCJpc0FycmF5IiwiZm9yRWFjaCIsInNldElucHV0IiwiaW5wdXQiLCJ0cmlnZ2VyIiwibmV3VmFsdWUiLCJnZXRBdHRyaWJ1dGUiLCJ2YWx1ZUF0dHJpYnV0ZSIsInRleHRDb250ZW50IiwidmFsdWUiLCJkZXN0cm95Iiwid2luZG93Il0sIm1hcHBpbmdzIjoiO0FBQUE7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTs7O0FBR0E7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0EsbURBQTJDLGNBQWM7O0FBRXpEO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsYUFBSztBQUNMO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0EsbUNBQTJCLDBCQUEwQixFQUFFO0FBQ3ZELHlDQUFpQyxlQUFlO0FBQ2hEO0FBQ0E7QUFDQTs7QUFFQTtBQUNBLDhEQUFzRCwrREFBK0Q7O0FBRXJIO0FBQ0E7O0FBRUE7QUFDQTs7Ozs7Ozs7Ozs7Ozs7QUNoRUEsSUFBTUEscUJBQXFCO0FBQ3pCQyxNQUR5QixnQkFDcEJDLElBRG9CLEVBQ2Q7QUFDVCxTQUFLQSxJQUFMLEdBQVlBLElBQVo7QUFDQSxTQUFLQyxNQUFMLEdBQWNELEtBQUtDLE1BQUwsQ0FBWUgsa0JBQVosS0FBbUMsS0FBS0UsSUFBTCxDQUFVQyxNQUFWLENBQWlCSCxrQkFBakIsR0FBc0MsRUFBekUsQ0FBZDs7QUFFQSxTQUFLSSxZQUFMLEdBQW9CLEVBQXBCOztBQUVBLFNBQUtDLFNBQUw7QUFDRCxHQVJ3QjtBQVV6QkEsV0FWeUIsdUJBVWI7QUFDVixTQUFLRCxZQUFMLENBQWtCRSxTQUFsQixHQUE4QixLQUFLQSxTQUFMLENBQWVDLElBQWYsQ0FBb0IsSUFBcEIsQ0FBOUI7QUFDQSxTQUFLTCxJQUFMLENBQVVNLElBQVYsQ0FBZUEsSUFBZixDQUFvQkMsZ0JBQXBCLENBQXFDLFVBQXJDLEVBQWlELEtBQUtMLFlBQUwsQ0FBa0JFLFNBQW5FO0FBQ0QsR0Fid0I7QUFlekJJLGNBZnlCLDBCQWVWO0FBQ2IsU0FBS1IsSUFBTCxDQUFVTSxJQUFWLENBQWVBLElBQWYsQ0FBb0JHLG1CQUFwQixDQUF3QyxVQUF4QyxFQUFvRCxLQUFLUCxZQUFMLENBQWtCRSxTQUF0RTtBQUNELEdBakJ3QjtBQW1CekJBLFdBbkJ5QixxQkFtQmZNLENBbkJlLEVBbUJaO0FBQUE7O0FBQ1gsUUFBTUMsZUFBZUQsRUFBRUUsTUFBRixDQUFTQyxRQUE5Qjs7QUFFQSxRQUFJLENBQUNDLE1BQU1DLE9BQU4sQ0FBYyxLQUFLZCxNQUFuQixDQUFMLEVBQWlDLEtBQUtBLE1BQUwsR0FBYyxDQUFDLEtBQUtBLE1BQU4sQ0FBZDs7QUFFakMsU0FBS0EsTUFBTCxDQUFZZSxPQUFaLENBQW9CO0FBQUEsYUFBVSxNQUFLQyxRQUFMLENBQWNoQixNQUFkLEVBQXNCVSxZQUF0QixDQUFWO0FBQUEsS0FBcEI7QUFDRCxHQXpCd0I7QUEyQnpCTSxVQTNCeUIsb0JBMkJoQmhCLE1BM0JnQixFQTJCUlUsWUEzQlEsRUEyQk07QUFDN0IsUUFBTU8sUUFBUWpCLE9BQU9pQixLQUFQLElBQWdCLEtBQUtsQixJQUFMLENBQVVtQixPQUF4QztBQUNBLFFBQU1DLFdBQVdULGFBQWFVLFlBQWIsQ0FBMEJwQixPQUFPcUIsY0FBakMsS0FBb0RYLGFBQWFZLFdBQWxGOztBQUVBTCxVQUFNTSxLQUFOLEdBQWNKLFFBQWQ7QUFDRCxHQWhDd0I7QUFrQ3pCSyxTQWxDeUIscUJBa0NmO0FBQ1IsU0FBS2pCLFlBQUw7QUFDRDtBQXBDd0IsQ0FBM0I7O0FBdUNBa0IsT0FBTzVCLGtCQUFQLEdBQTRCQSxrQkFBNUI7O2tCQUVlQSxrQiIsImZpbGUiOiIuL2Rpc3QvcGx1Z2lucy9pbnB1dF9zZXR0ZXIuanMiLCJzb3VyY2VzQ29udGVudCI6WyIgXHQvLyBUaGUgbW9kdWxlIGNhY2hlXG4gXHR2YXIgaW5zdGFsbGVkTW9kdWxlcyA9IHt9O1xuXG4gXHQvLyBUaGUgcmVxdWlyZSBmdW5jdGlvblxuIFx0ZnVuY3Rpb24gX193ZWJwYWNrX3JlcXVpcmVfXyhtb2R1bGVJZCkge1xuXG4gXHRcdC8vIENoZWNrIGlmIG1vZHVsZSBpcyBpbiBjYWNoZVxuIFx0XHRpZihpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXSlcbiBcdFx0XHRyZXR1cm4gaW5zdGFsbGVkTW9kdWxlc1ttb2R1bGVJZF0uZXhwb3J0cztcblxuIFx0XHQvLyBDcmVhdGUgYSBuZXcgbW9kdWxlIChhbmQgcHV0IGl0IGludG8gdGhlIGNhY2hlKVxuIFx0XHR2YXIgbW9kdWxlID0gaW5zdGFsbGVkTW9kdWxlc1ttb2R1bGVJZF0gPSB7XG4gXHRcdFx0aTogbW9kdWxlSWQsXG4gXHRcdFx0bDogZmFsc2UsXG4gXHRcdFx0ZXhwb3J0czoge31cbiBcdFx0fTtcblxuIFx0XHQvLyBFeGVjdXRlIHRoZSBtb2R1bGUgZnVuY3Rpb25cbiBcdFx0bW9kdWxlc1ttb2R1bGVJZF0uY2FsbChtb2R1bGUuZXhwb3J0cywgbW9kdWxlLCBtb2R1bGUuZXhwb3J0cywgX193ZWJwYWNrX3JlcXVpcmVfXyk7XG5cbiBcdFx0Ly8gRmxhZyB0aGUgbW9kdWxlIGFzIGxvYWRlZFxuIFx0XHRtb2R1bGUubCA9IHRydWU7XG5cbiBcdFx0Ly8gUmV0dXJuIHRoZSBleHBvcnRzIG9mIHRoZSBtb2R1bGVcbiBcdFx0cmV0dXJuIG1vZHVsZS5leHBvcnRzO1xuIFx0fVxuXG5cbiBcdC8vIGV4cG9zZSB0aGUgbW9kdWxlcyBvYmplY3QgKF9fd2VicGFja19tb2R1bGVzX18pXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm0gPSBtb2R1bGVzO1xuXG4gXHQvLyBleHBvc2UgdGhlIG1vZHVsZSBjYWNoZVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5jID0gaW5zdGFsbGVkTW9kdWxlcztcblxuIFx0Ly8gaWRlbnRpdHkgZnVuY3Rpb24gZm9yIGNhbGxpbmcgaGFybW9ueSBpbXBvcnRzIHdpdGggdGhlIGNvcnJlY3QgY29udGV4dFxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5pID0gZnVuY3Rpb24odmFsdWUpIHsgcmV0dXJuIHZhbHVlOyB9O1xuXG4gXHQvLyBkZWZpbmUgZ2V0dGVyIGZ1bmN0aW9uIGZvciBoYXJtb255IGV4cG9ydHNcbiBcdF9fd2VicGFja19yZXF1aXJlX18uZCA9IGZ1bmN0aW9uKGV4cG9ydHMsIG5hbWUsIGdldHRlcikge1xuIFx0XHRpZighX193ZWJwYWNrX3JlcXVpcmVfXy5vKGV4cG9ydHMsIG5hbWUpKSB7XG4gXHRcdFx0T2JqZWN0LmRlZmluZVByb3BlcnR5KGV4cG9ydHMsIG5hbWUsIHtcbiBcdFx0XHRcdGNvbmZpZ3VyYWJsZTogZmFsc2UsXG4gXHRcdFx0XHRlbnVtZXJhYmxlOiB0cnVlLFxuIFx0XHRcdFx0Z2V0OiBnZXR0ZXJcbiBcdFx0XHR9KTtcbiBcdFx0fVxuIFx0fTtcblxuIFx0Ly8gZ2V0RGVmYXVsdEV4cG9ydCBmdW5jdGlvbiBmb3IgY29tcGF0aWJpbGl0eSB3aXRoIG5vbi1oYXJtb255IG1vZHVsZXNcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubiA9IGZ1bmN0aW9uKG1vZHVsZSkge1xuIFx0XHR2YXIgZ2V0dGVyID0gbW9kdWxlICYmIG1vZHVsZS5fX2VzTW9kdWxlID9cbiBcdFx0XHRmdW5jdGlvbiBnZXREZWZhdWx0KCkgeyByZXR1cm4gbW9kdWxlWydkZWZhdWx0J107IH0gOlxuIFx0XHRcdGZ1bmN0aW9uIGdldE1vZHVsZUV4cG9ydHMoKSB7IHJldHVybiBtb2R1bGU7IH07XG4gXHRcdF9fd2VicGFja19yZXF1aXJlX18uZChnZXR0ZXIsICdhJywgZ2V0dGVyKTtcbiBcdFx0cmV0dXJuIGdldHRlcjtcbiBcdH07XG5cbiBcdC8vIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbFxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5vID0gZnVuY3Rpb24ob2JqZWN0LCBwcm9wZXJ0eSkgeyByZXR1cm4gT2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsKG9iamVjdCwgcHJvcGVydHkpOyB9O1xuXG4gXHQvLyBfX3dlYnBhY2tfcHVibGljX3BhdGhfX1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5wID0gXCJcIjtcblxuIFx0Ly8gTG9hZCBlbnRyeSBtb2R1bGUgYW5kIHJldHVybiBleHBvcnRzXG4gXHRyZXR1cm4gX193ZWJwYWNrX3JlcXVpcmVfXyhfX3dlYnBhY2tfcmVxdWlyZV9fLnMgPSAxMyk7XG5cblxuXG4vLyBXRUJQQUNLIEZPT1RFUiAvL1xuLy8gd2VicGFjay9ib290c3RyYXAgYTVmZGU1NjJhOGRjY2M3ZTliMTkiLCJjb25zdCBkcm9wbGFiSW5wdXRTZXR0ZXIgPSB7XG4gIGluaXQoaG9vaykge1xuICAgIHRoaXMuaG9vayA9IGhvb2s7XG4gICAgdGhpcy5jb25maWcgPSBob29rLmNvbmZpZy5kcm9wbGFiSW5wdXRTZXR0ZXIgfHwgKHRoaXMuaG9vay5jb25maWcuZHJvcGxhYklucHV0U2V0dGVyID0ge30pO1xuXG4gICAgdGhpcy5ldmVudFdyYXBwZXIgPSB7fTtcblxuICAgIHRoaXMuYWRkRXZlbnRzKCk7XG4gIH0sXG5cbiAgYWRkRXZlbnRzKCkge1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLnNldElucHV0cyA9IHRoaXMuc2V0SW5wdXRzLmJpbmQodGhpcyk7XG4gICAgdGhpcy5ob29rLmxpc3QubGlzdC5hZGRFdmVudExpc3RlbmVyKCdjbGljay5kbCcsIHRoaXMuZXZlbnRXcmFwcGVyLnNldElucHV0cyk7XG4gIH0sXG5cbiAgcmVtb3ZlRXZlbnRzKCkge1xuICAgIHRoaXMuaG9vay5saXN0Lmxpc3QucmVtb3ZlRXZlbnRMaXN0ZW5lcignY2xpY2suZGwnLCB0aGlzLmV2ZW50V3JhcHBlci5zZXRJbnB1dHMpO1xuICB9LFxuXG4gIHNldElucHV0cyhlKSB7XG4gICAgY29uc3Qgc2VsZWN0ZWRJdGVtID0gZS5kZXRhaWwuc2VsZWN0ZWQ7XG5cbiAgICBpZiAoIUFycmF5LmlzQXJyYXkodGhpcy5jb25maWcpKSB0aGlzLmNvbmZpZyA9IFt0aGlzLmNvbmZpZ107XG5cbiAgICB0aGlzLmNvbmZpZy5mb3JFYWNoKGNvbmZpZyA9PiB0aGlzLnNldElucHV0KGNvbmZpZywgc2VsZWN0ZWRJdGVtKSk7XG4gIH0sXG5cbiAgc2V0SW5wdXQoY29uZmlnLCBzZWxlY3RlZEl0ZW0pIHtcbiAgICBjb25zdCBpbnB1dCA9IGNvbmZpZy5pbnB1dCB8fCB0aGlzLmhvb2sudHJpZ2dlcjtcbiAgICBjb25zdCBuZXdWYWx1ZSA9IHNlbGVjdGVkSXRlbS5nZXRBdHRyaWJ1dGUoY29uZmlnLnZhbHVlQXR0cmlidXRlKSB8fCBzZWxlY3RlZEl0ZW0udGV4dENvbnRlbnQ7XG5cbiAgICBpbnB1dC52YWx1ZSA9IG5ld1ZhbHVlO1xuICB9LFxuXG4gIGRlc3Ryb3koKSB7XG4gICAgdGhpcy5yZW1vdmVFdmVudHMoKTtcbiAgfSxcbn07XG5cbndpbmRvdy5kcm9wbGFiSW5wdXRTZXR0ZXIgPSBkcm9wbGFiSW5wdXRTZXR0ZXI7XG5cbmV4cG9ydCBkZWZhdWx0IGRyb3BsYWJJbnB1dFNldHRlcjtcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyAuL3NyYy9wbHVnaW5zL2lucHV0X3NldHRlci5qcyJdLCJzb3VyY2VSb290IjoiIn0=