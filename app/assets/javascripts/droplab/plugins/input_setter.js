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

window.droplabInputSetter = droplabInputSetter;

exports.default = droplabInputSetter;

/***/ })

/******/ });
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAgZjM3NjcyYjdmNTI4YjQ3MmE0NGM/ZWM1ZiIsIndlYnBhY2s6Ly8vLi9zcmMvcGx1Z2lucy9pbnB1dF9zZXR0ZXIuanMiXSwibmFtZXMiOlsiZHJvcGxhYklucHV0U2V0dGVyIiwiaW5pdCIsImhvb2siLCJjb25maWciLCJldmVudFdyYXBwZXIiLCJhZGRFdmVudHMiLCJzZXRJbnB1dHMiLCJiaW5kIiwibGlzdCIsImFkZEV2ZW50TGlzdGVuZXIiLCJyZW1vdmVFdmVudHMiLCJyZW1vdmVFdmVudExpc3RlbmVyIiwiZSIsInNlbGVjdGVkSXRlbSIsImRldGFpbCIsInNlbGVjdGVkIiwiQXJyYXkiLCJpc0FycmF5IiwiZm9yRWFjaCIsInNldElucHV0IiwiaW5wdXQiLCJ0cmlnZ2VyIiwibmV3VmFsdWUiLCJnZXRBdHRyaWJ1dGUiLCJ2YWx1ZUF0dHJpYnV0ZSIsInRhZ05hbWUiLCJ2YWx1ZSIsInRleHRDb250ZW50IiwiZGVzdHJveSIsIndpbmRvdyJdLCJtYXBwaW5ncyI6IjtBQUFBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7OztBQUdBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBLG1EQUEyQyxjQUFjOztBQUV6RDtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLGFBQUs7QUFDTDtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBLG1DQUEyQiwwQkFBMEIsRUFBRTtBQUN2RCx5Q0FBaUMsZUFBZTtBQUNoRDtBQUNBO0FBQ0E7O0FBRUE7QUFDQSw4REFBc0QsK0RBQStEOztBQUVySDtBQUNBOztBQUVBO0FBQ0E7Ozs7Ozs7Ozs7Ozs7O0FDaEVBLElBQU1BLHFCQUFxQjtBQUN6QkMsTUFEeUIsZ0JBQ3BCQyxJQURvQixFQUNkO0FBQ1QsU0FBS0EsSUFBTCxHQUFZQSxJQUFaO0FBQ0EsU0FBS0MsTUFBTCxHQUFjRCxLQUFLQyxNQUFMLENBQVlILGtCQUFaLEtBQW1DLEtBQUtFLElBQUwsQ0FBVUMsTUFBVixDQUFpQkgsa0JBQWpCLEdBQXNDLEVBQXpFLENBQWQ7O0FBRUEsU0FBS0ksWUFBTCxHQUFvQixFQUFwQjs7QUFFQSxTQUFLQyxTQUFMO0FBQ0QsR0FSd0I7QUFVekJBLFdBVnlCLHVCQVViO0FBQ1YsU0FBS0QsWUFBTCxDQUFrQkUsU0FBbEIsR0FBOEIsS0FBS0EsU0FBTCxDQUFlQyxJQUFmLENBQW9CLElBQXBCLENBQTlCO0FBQ0EsU0FBS0wsSUFBTCxDQUFVTSxJQUFWLENBQWVBLElBQWYsQ0FBb0JDLGdCQUFwQixDQUFxQyxVQUFyQyxFQUFpRCxLQUFLTCxZQUFMLENBQWtCRSxTQUFuRTtBQUNELEdBYndCO0FBZXpCSSxjQWZ5QiwwQkFlVjtBQUNiLFNBQUtSLElBQUwsQ0FBVU0sSUFBVixDQUFlQSxJQUFmLENBQW9CRyxtQkFBcEIsQ0FBd0MsVUFBeEMsRUFBb0QsS0FBS1AsWUFBTCxDQUFrQkUsU0FBdEU7QUFDRCxHQWpCd0I7QUFtQnpCQSxXQW5CeUIscUJBbUJmTSxDQW5CZSxFQW1CWjtBQUFBOztBQUNYLFFBQU1DLGVBQWVELEVBQUVFLE1BQUYsQ0FBU0MsUUFBOUI7O0FBRUEsUUFBSSxDQUFDQyxNQUFNQyxPQUFOLENBQWMsS0FBS2QsTUFBbkIsQ0FBTCxFQUFpQyxLQUFLQSxNQUFMLEdBQWMsQ0FBQyxLQUFLQSxNQUFOLENBQWQ7O0FBRWpDLFNBQUtBLE1BQUwsQ0FBWWUsT0FBWixDQUFvQjtBQUFBLGFBQVUsTUFBS0MsUUFBTCxDQUFjaEIsTUFBZCxFQUFzQlUsWUFBdEIsQ0FBVjtBQUFBLEtBQXBCO0FBQ0QsR0F6QndCO0FBMkJ6Qk0sVUEzQnlCLG9CQTJCaEJoQixNQTNCZ0IsRUEyQlJVLFlBM0JRLEVBMkJNO0FBQzdCLFFBQU1PLFFBQVFqQixPQUFPaUIsS0FBUCxJQUFnQixLQUFLbEIsSUFBTCxDQUFVbUIsT0FBeEM7QUFDQSxRQUFNQyxXQUFXVCxhQUFhVSxZQUFiLENBQTBCcEIsT0FBT3FCLGNBQWpDLENBQWpCOztBQUVBLFFBQUlKLE1BQU1LLE9BQU4sS0FBa0IsT0FBdEIsRUFBK0I7QUFDN0JMLFlBQU1NLEtBQU4sR0FBY0osUUFBZDtBQUNELEtBRkQsTUFFTztBQUNMRixZQUFNTyxXQUFOLEdBQW9CTCxRQUFwQjtBQUNEO0FBQ0YsR0FwQ3dCO0FBc0N6Qk0sU0F0Q3lCLHFCQXNDZjtBQUNSLFNBQUtsQixZQUFMO0FBQ0Q7QUF4Q3dCLENBQTNCOztBQTJDQW1CLE9BQU83QixrQkFBUCxHQUE0QkEsa0JBQTVCOztrQkFFZUEsa0IiLCJmaWxlIjoiLi9kaXN0L3BsdWdpbnMvaW5wdXRfc2V0dGVyLmpzIiwic291cmNlc0NvbnRlbnQiOlsiIFx0Ly8gVGhlIG1vZHVsZSBjYWNoZVxuIFx0dmFyIGluc3RhbGxlZE1vZHVsZXMgPSB7fTtcblxuIFx0Ly8gVGhlIHJlcXVpcmUgZnVuY3Rpb25cbiBcdGZ1bmN0aW9uIF9fd2VicGFja19yZXF1aXJlX18obW9kdWxlSWQpIHtcblxuIFx0XHQvLyBDaGVjayBpZiBtb2R1bGUgaXMgaW4gY2FjaGVcbiBcdFx0aWYoaW5zdGFsbGVkTW9kdWxlc1ttb2R1bGVJZF0pXG4gXHRcdFx0cmV0dXJuIGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdLmV4cG9ydHM7XG5cbiBcdFx0Ly8gQ3JlYXRlIGEgbmV3IG1vZHVsZSAoYW5kIHB1dCBpdCBpbnRvIHRoZSBjYWNoZSlcbiBcdFx0dmFyIG1vZHVsZSA9IGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdID0ge1xuIFx0XHRcdGk6IG1vZHVsZUlkLFxuIFx0XHRcdGw6IGZhbHNlLFxuIFx0XHRcdGV4cG9ydHM6IHt9XG4gXHRcdH07XG5cbiBcdFx0Ly8gRXhlY3V0ZSB0aGUgbW9kdWxlIGZ1bmN0aW9uXG4gXHRcdG1vZHVsZXNbbW9kdWxlSWRdLmNhbGwobW9kdWxlLmV4cG9ydHMsIG1vZHVsZSwgbW9kdWxlLmV4cG9ydHMsIF9fd2VicGFja19yZXF1aXJlX18pO1xuXG4gXHRcdC8vIEZsYWcgdGhlIG1vZHVsZSBhcyBsb2FkZWRcbiBcdFx0bW9kdWxlLmwgPSB0cnVlO1xuXG4gXHRcdC8vIFJldHVybiB0aGUgZXhwb3J0cyBvZiB0aGUgbW9kdWxlXG4gXHRcdHJldHVybiBtb2R1bGUuZXhwb3J0cztcbiBcdH1cblxuXG4gXHQvLyBleHBvc2UgdGhlIG1vZHVsZXMgb2JqZWN0IChfX3dlYnBhY2tfbW9kdWxlc19fKVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5tID0gbW9kdWxlcztcblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGUgY2FjaGVcbiBcdF9fd2VicGFja19yZXF1aXJlX18uYyA9IGluc3RhbGxlZE1vZHVsZXM7XG5cbiBcdC8vIGlkZW50aXR5IGZ1bmN0aW9uIGZvciBjYWxsaW5nIGhhcm1vbnkgaW1wb3J0cyB3aXRoIHRoZSBjb3JyZWN0IGNvbnRleHRcbiBcdF9fd2VicGFja19yZXF1aXJlX18uaSA9IGZ1bmN0aW9uKHZhbHVlKSB7IHJldHVybiB2YWx1ZTsgfTtcblxuIFx0Ly8gZGVmaW5lIGdldHRlciBmdW5jdGlvbiBmb3IgaGFybW9ueSBleHBvcnRzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQgPSBmdW5jdGlvbihleHBvcnRzLCBuYW1lLCBnZXR0ZXIpIHtcbiBcdFx0aWYoIV9fd2VicGFja19yZXF1aXJlX18ubyhleHBvcnRzLCBuYW1lKSkge1xuIFx0XHRcdE9iamVjdC5kZWZpbmVQcm9wZXJ0eShleHBvcnRzLCBuYW1lLCB7XG4gXHRcdFx0XHRjb25maWd1cmFibGU6IGZhbHNlLFxuIFx0XHRcdFx0ZW51bWVyYWJsZTogdHJ1ZSxcbiBcdFx0XHRcdGdldDogZ2V0dGVyXG4gXHRcdFx0fSk7XG4gXHRcdH1cbiBcdH07XG5cbiBcdC8vIGdldERlZmF1bHRFeHBvcnQgZnVuY3Rpb24gZm9yIGNvbXBhdGliaWxpdHkgd2l0aCBub24taGFybW9ueSBtb2R1bGVzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm4gPSBmdW5jdGlvbihtb2R1bGUpIHtcbiBcdFx0dmFyIGdldHRlciA9IG1vZHVsZSAmJiBtb2R1bGUuX19lc01vZHVsZSA/XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0RGVmYXVsdCgpIHsgcmV0dXJuIG1vZHVsZVsnZGVmYXVsdCddOyB9IDpcbiBcdFx0XHRmdW5jdGlvbiBnZXRNb2R1bGVFeHBvcnRzKCkgeyByZXR1cm4gbW9kdWxlOyB9O1xuIFx0XHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQoZ2V0dGVyLCAnYScsIGdldHRlcik7XG4gXHRcdHJldHVybiBnZXR0ZXI7XG4gXHR9O1xuXG4gXHQvLyBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGxcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubyA9IGZ1bmN0aW9uKG9iamVjdCwgcHJvcGVydHkpIHsgcmV0dXJuIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbChvYmplY3QsIHByb3BlcnR5KTsgfTtcblxuIFx0Ly8gX193ZWJwYWNrX3B1YmxpY19wYXRoX19cbiBcdF9fd2VicGFja19yZXF1aXJlX18ucCA9IFwiXCI7XG5cbiBcdC8vIExvYWQgZW50cnkgbW9kdWxlIGFuZCByZXR1cm4gZXhwb3J0c1xuIFx0cmV0dXJuIF9fd2VicGFja19yZXF1aXJlX18oX193ZWJwYWNrX3JlcXVpcmVfXy5zID0gMTMpO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIHdlYnBhY2svYm9vdHN0cmFwIGYzNzY3MmI3ZjUyOGI0NzJhNDRjIiwiY29uc3QgZHJvcGxhYklucHV0U2V0dGVyID0ge1xuICBpbml0KGhvb2spIHtcbiAgICB0aGlzLmhvb2sgPSBob29rO1xuICAgIHRoaXMuY29uZmlnID0gaG9vay5jb25maWcuZHJvcGxhYklucHV0U2V0dGVyIHx8ICh0aGlzLmhvb2suY29uZmlnLmRyb3BsYWJJbnB1dFNldHRlciA9IHt9KTtcblxuICAgIHRoaXMuZXZlbnRXcmFwcGVyID0ge307XG5cbiAgICB0aGlzLmFkZEV2ZW50cygpO1xuICB9LFxuXG4gIGFkZEV2ZW50cygpIHtcbiAgICB0aGlzLmV2ZW50V3JhcHBlci5zZXRJbnB1dHMgPSB0aGlzLnNldElucHV0cy5iaW5kKHRoaXMpO1xuICAgIHRoaXMuaG9vay5saXN0Lmxpc3QuYWRkRXZlbnRMaXN0ZW5lcignY2xpY2suZGwnLCB0aGlzLmV2ZW50V3JhcHBlci5zZXRJbnB1dHMpO1xuICB9LFxuXG4gIHJlbW92ZUV2ZW50cygpIHtcbiAgICB0aGlzLmhvb2subGlzdC5saXN0LnJlbW92ZUV2ZW50TGlzdGVuZXIoJ2NsaWNrLmRsJywgdGhpcy5ldmVudFdyYXBwZXIuc2V0SW5wdXRzKTtcbiAgfSxcblxuICBzZXRJbnB1dHMoZSkge1xuICAgIGNvbnN0IHNlbGVjdGVkSXRlbSA9IGUuZGV0YWlsLnNlbGVjdGVkO1xuXG4gICAgaWYgKCFBcnJheS5pc0FycmF5KHRoaXMuY29uZmlnKSkgdGhpcy5jb25maWcgPSBbdGhpcy5jb25maWddO1xuXG4gICAgdGhpcy5jb25maWcuZm9yRWFjaChjb25maWcgPT4gdGhpcy5zZXRJbnB1dChjb25maWcsIHNlbGVjdGVkSXRlbSkpO1xuICB9LFxuXG4gIHNldElucHV0KGNvbmZpZywgc2VsZWN0ZWRJdGVtKSB7XG4gICAgY29uc3QgaW5wdXQgPSBjb25maWcuaW5wdXQgfHwgdGhpcy5ob29rLnRyaWdnZXI7XG4gICAgY29uc3QgbmV3VmFsdWUgPSBzZWxlY3RlZEl0ZW0uZ2V0QXR0cmlidXRlKGNvbmZpZy52YWx1ZUF0dHJpYnV0ZSk7XG5cbiAgICBpZiAoaW5wdXQudGFnTmFtZSA9PT0gJ0lOUFVUJykge1xuICAgICAgaW5wdXQudmFsdWUgPSBuZXdWYWx1ZTtcbiAgICB9IGVsc2Uge1xuICAgICAgaW5wdXQudGV4dENvbnRlbnQgPSBuZXdWYWx1ZTtcbiAgICB9XG4gIH0sXG5cbiAgZGVzdHJveSgpIHtcbiAgICB0aGlzLnJlbW92ZUV2ZW50cygpO1xuICB9LFxufTtcblxud2luZG93LmRyb3BsYWJJbnB1dFNldHRlciA9IGRyb3BsYWJJbnB1dFNldHRlcjtcblxuZXhwb3J0IGRlZmF1bHQgZHJvcGxhYklucHV0U2V0dGVyO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL3BsdWdpbnMvaW5wdXRfc2V0dGVyLmpzIl0sInNvdXJjZVJvb3QiOiIifQ==