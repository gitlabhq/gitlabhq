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
/******/ 	return __webpack_require__(__webpack_require__.s = 7);
/******/ })
/************************************************************************/
/******/ ({

/***/ 7:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var droplabFilter = {
  keydown: function keydown(e) {
    var hiddenCount = 0;
    var dataHiddenCount = 0;

    var list = e.detail.hook.list;
    var data = list.data;
    var value = e.detail.hook.trigger.value.toLowerCase();
    var config = e.detail.hook.config.droplabFilter;
    var matches = [];
    var filterFunction;
    // will only work on dynamically set data
    if (!data) {
      return;
    }

    if (config && config.filterFunction && typeof config.filterFunction === 'function') {
      filterFunction = config.filterFunction;
    } else {
      filterFunction = function filterFunction(o) {
        // cheap string search
        o.droplab_hidden = o[config.template].toLowerCase().indexOf(value) === -1;
        return o;
      };
    }

    dataHiddenCount = data.filter(function (o) {
      return !o.droplab_hidden;
    }).length;

    matches = data.map(function (o) {
      return filterFunction(o, value);
    });

    hiddenCount = matches.filter(function (o) {
      return !o.droplab_hidden;
    }).length;

    if (dataHiddenCount !== hiddenCount) {
      list.render(matches);
      list.currentIndex = 0;
    }
  },

  debounceKeydown: function debounceKeydown(e) {
    if ([13, // enter
    16, // shift
    17, // ctrl
    18, // alt
    20, // caps lock
    37, // left arrow
    38, // up arrow
    39, // right arrow
    40, // down arrow
    91, // left window
    92, // right window
    93].indexOf(e.detail.which || e.detail.keyCode) > -1) return;

    if (this.timeout) clearTimeout(this.timeout);
    this.timeout = setTimeout(this.keydown.bind(this, e), 200);
  },

  init: function init(hook) {
    var config = hook.config.droplabFilter;

    if (!config || !config.template) return;

    this.hook = hook;

    this.eventWrapper = {};
    this.eventWrapper.debounceKeydown = this.debounceKeydown.bind(this);

    this.hook.trigger.addEventListener('keydown.dl', this.eventWrapper.debounceKeydown);
    this.hook.trigger.addEventListener('mousedown.dl', this.eventWrapper.debounceKeydown);
  },

  destroy: function destroy() {
    this.hook.trigger.removeEventListener('keydown.dl', this.eventWrapper.debounceKeydown);
    this.hook.trigger.removeEventListener('mousedown.dl', this.eventWrapper.debounceKeydown);

    var dynamicList = this.hook.list.list.querySelector('[data-dynamic]');
    if (this.listTemplate && dynamicList) {
      dynamicList.outerHTML = this.listTemplate;
    }
  }
};

exports.default = droplabFilter;

/***/ })

/******/ });
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAgOTMzZmY3ZDVlZDM5M2RjNjNiY2E/MGFiZioqKioqKiIsIndlYnBhY2s6Ly8vLi9zcmMvcGx1Z2lucy9maWx0ZXIvZmlsdGVyLmpzP2Y0MWEiXSwibmFtZXMiOlsiZHJvcGxhYkZpbHRlciIsImtleWRvd24iLCJlIiwiaGlkZGVuQ291bnQiLCJkYXRhSGlkZGVuQ291bnQiLCJsaXN0IiwiZGV0YWlsIiwiaG9vayIsImRhdGEiLCJ2YWx1ZSIsInRyaWdnZXIiLCJ0b0xvd2VyQ2FzZSIsImNvbmZpZyIsIm1hdGNoZXMiLCJmaWx0ZXJGdW5jdGlvbiIsIm8iLCJkcm9wbGFiX2hpZGRlbiIsInRlbXBsYXRlIiwiaW5kZXhPZiIsImZpbHRlciIsImxlbmd0aCIsIm1hcCIsInJlbmRlciIsImN1cnJlbnRJbmRleCIsImRlYm91bmNlS2V5ZG93biIsIndoaWNoIiwia2V5Q29kZSIsInRpbWVvdXQiLCJjbGVhclRpbWVvdXQiLCJzZXRUaW1lb3V0IiwiYmluZCIsImluaXQiLCJldmVudFdyYXBwZXIiLCJhZGRFdmVudExpc3RlbmVyIiwiZGVzdHJveSIsInJlbW92ZUV2ZW50TGlzdGVuZXIiLCJkeW5hbWljTGlzdCIsInF1ZXJ5U2VsZWN0b3IiLCJsaXN0VGVtcGxhdGUiLCJvdXRlckhUTUwiXSwibWFwcGluZ3MiOiI7QUFBQTtBQUNBOztBQUVBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBOzs7QUFHQTtBQUNBOztBQUVBO0FBQ0E7O0FBRUE7QUFDQSxtREFBMkMsY0FBYzs7QUFFekQ7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxhQUFLO0FBQ0w7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQSxtQ0FBMkIsMEJBQTBCLEVBQUU7QUFDdkQseUNBQWlDLGVBQWU7QUFDaEQ7QUFDQTtBQUNBOztBQUVBO0FBQ0EsOERBQXNELCtEQUErRDs7QUFFckg7QUFDQTs7QUFFQTtBQUNBOzs7Ozs7Ozs7Ozs7OztBQ2hFQSxJQUFNQSxnQkFBZ0I7QUFDcEJDLFdBQVMsaUJBQVNDLENBQVQsRUFBVztBQUNsQixRQUFJQyxjQUFjLENBQWxCO0FBQ0EsUUFBSUMsa0JBQWtCLENBQXRCOztBQUVBLFFBQUlDLE9BQU9ILEVBQUVJLE1BQUYsQ0FBU0MsSUFBVCxDQUFjRixJQUF6QjtBQUNBLFFBQUlHLE9BQU9ILEtBQUtHLElBQWhCO0FBQ0EsUUFBSUMsUUFBUVAsRUFBRUksTUFBRixDQUFTQyxJQUFULENBQWNHLE9BQWQsQ0FBc0JELEtBQXRCLENBQTRCRSxXQUE1QixFQUFaO0FBQ0EsUUFBSUMsU0FBU1YsRUFBRUksTUFBRixDQUFTQyxJQUFULENBQWNLLE1BQWQsQ0FBcUJaLGFBQWxDO0FBQ0EsUUFBSWEsVUFBVSxFQUFkO0FBQ0EsUUFBSUMsY0FBSjtBQUNBO0FBQ0EsUUFBRyxDQUFDTixJQUFKLEVBQVM7QUFDUDtBQUNEOztBQUVELFFBQUlJLFVBQVVBLE9BQU9FLGNBQWpCLElBQW1DLE9BQU9GLE9BQU9FLGNBQWQsS0FBaUMsVUFBeEUsRUFBb0Y7QUFDbEZBLHVCQUFpQkYsT0FBT0UsY0FBeEI7QUFDRCxLQUZELE1BRU87QUFDTEEsdUJBQWlCLHdCQUFTQyxDQUFULEVBQVc7QUFDMUI7QUFDQUEsVUFBRUMsY0FBRixHQUFtQkQsRUFBRUgsT0FBT0ssUUFBVCxFQUFtQk4sV0FBbkIsR0FBaUNPLE9BQWpDLENBQXlDVCxLQUF6QyxNQUFvRCxDQUFDLENBQXhFO0FBQ0EsZUFBT00sQ0FBUDtBQUNELE9BSkQ7QUFLRDs7QUFFRFgsc0JBQWtCSSxLQUFLVyxNQUFMLENBQVksVUFBU0osQ0FBVCxFQUFZO0FBQ3hDLGFBQU8sQ0FBQ0EsRUFBRUMsY0FBVjtBQUNELEtBRmlCLEVBRWZJLE1BRkg7O0FBSUFQLGNBQVVMLEtBQUthLEdBQUwsQ0FBUyxVQUFTTixDQUFULEVBQVk7QUFDN0IsYUFBT0QsZUFBZUMsQ0FBZixFQUFrQk4sS0FBbEIsQ0FBUDtBQUNELEtBRlMsQ0FBVjs7QUFJQU4sa0JBQWNVLFFBQVFNLE1BQVIsQ0FBZSxVQUFTSixDQUFULEVBQVk7QUFDdkMsYUFBTyxDQUFDQSxFQUFFQyxjQUFWO0FBQ0QsS0FGYSxFQUVYSSxNQUZIOztBQUlBLFFBQUloQixvQkFBb0JELFdBQXhCLEVBQXFDO0FBQ25DRSxXQUFLaUIsTUFBTCxDQUFZVCxPQUFaO0FBQ0FSLFdBQUtrQixZQUFMLEdBQW9CLENBQXBCO0FBQ0Q7QUFDRixHQTFDbUI7O0FBNENwQkMsbUJBQWlCLFNBQVNBLGVBQVQsQ0FBeUJ0QixDQUF6QixFQUE0QjtBQUMzQyxRQUFJLENBQ0YsRUFERSxFQUNFO0FBQ0osTUFGRSxFQUVFO0FBQ0osTUFIRSxFQUdFO0FBQ0osTUFKRSxFQUlFO0FBQ0osTUFMRSxFQUtFO0FBQ0osTUFORSxFQU1FO0FBQ0osTUFQRSxFQU9FO0FBQ0osTUFSRSxFQVFFO0FBQ0osTUFURSxFQVNFO0FBQ0osTUFWRSxFQVVFO0FBQ0osTUFYRSxFQVdFO0FBQ0osTUFaRSxFQWFGZ0IsT0FiRSxDQWFNaEIsRUFBRUksTUFBRixDQUFTbUIsS0FBVCxJQUFrQnZCLEVBQUVJLE1BQUYsQ0FBU29CLE9BYmpDLElBYTRDLENBQUMsQ0FiakQsRUFhb0Q7O0FBRXBELFFBQUksS0FBS0MsT0FBVCxFQUFrQkMsYUFBYSxLQUFLRCxPQUFsQjtBQUNsQixTQUFLQSxPQUFMLEdBQWVFLFdBQVcsS0FBSzVCLE9BQUwsQ0FBYTZCLElBQWIsQ0FBa0IsSUFBbEIsRUFBd0I1QixDQUF4QixDQUFYLEVBQXVDLEdBQXZDLENBQWY7QUFDRCxHQTlEbUI7O0FBZ0VwQjZCLFFBQU0sU0FBU0EsSUFBVCxDQUFjeEIsSUFBZCxFQUFvQjtBQUN4QixRQUFJSyxTQUFTTCxLQUFLSyxNQUFMLENBQVlaLGFBQXpCOztBQUVBLFFBQUksQ0FBQ1ksTUFBRCxJQUFXLENBQUNBLE9BQU9LLFFBQXZCLEVBQWlDOztBQUVqQyxTQUFLVixJQUFMLEdBQVlBLElBQVo7O0FBRUEsU0FBS3lCLFlBQUwsR0FBb0IsRUFBcEI7QUFDQSxTQUFLQSxZQUFMLENBQWtCUixlQUFsQixHQUFvQyxLQUFLQSxlQUFMLENBQXFCTSxJQUFyQixDQUEwQixJQUExQixDQUFwQzs7QUFFQSxTQUFLdkIsSUFBTCxDQUFVRyxPQUFWLENBQWtCdUIsZ0JBQWxCLENBQW1DLFlBQW5DLEVBQWlELEtBQUtELFlBQUwsQ0FBa0JSLGVBQW5FO0FBQ0EsU0FBS2pCLElBQUwsQ0FBVUcsT0FBVixDQUFrQnVCLGdCQUFsQixDQUFtQyxjQUFuQyxFQUFtRCxLQUFLRCxZQUFMLENBQWtCUixlQUFyRTtBQUNELEdBNUVtQjs7QUE4RXBCVSxXQUFTLFNBQVNBLE9BQVQsR0FBbUI7QUFDMUIsU0FBSzNCLElBQUwsQ0FBVUcsT0FBVixDQUFrQnlCLG1CQUFsQixDQUFzQyxZQUF0QyxFQUFvRCxLQUFLSCxZQUFMLENBQWtCUixlQUF0RTtBQUNBLFNBQUtqQixJQUFMLENBQVVHLE9BQVYsQ0FBa0J5QixtQkFBbEIsQ0FBc0MsY0FBdEMsRUFBc0QsS0FBS0gsWUFBTCxDQUFrQlIsZUFBeEU7O0FBRUEsUUFBSVksY0FBYyxLQUFLN0IsSUFBTCxDQUFVRixJQUFWLENBQWVBLElBQWYsQ0FBb0JnQyxhQUFwQixDQUFrQyxnQkFBbEMsQ0FBbEI7QUFDQSxRQUFJLEtBQUtDLFlBQUwsSUFBcUJGLFdBQXpCLEVBQXNDO0FBQ3BDQSxrQkFBWUcsU0FBWixHQUF3QixLQUFLRCxZQUE3QjtBQUNEO0FBQ0Y7QUF0Rm1CLENBQXRCOztrQkF5RmV0QyxhIiwiZmlsZSI6Ii4vZGlzdC9wbHVnaW5zL2ZpbHRlci5qcyIsInNvdXJjZXNDb250ZW50IjpbIiBcdC8vIFRoZSBtb2R1bGUgY2FjaGVcbiBcdHZhciBpbnN0YWxsZWRNb2R1bGVzID0ge307XG5cbiBcdC8vIFRoZSByZXF1aXJlIGZ1bmN0aW9uXG4gXHRmdW5jdGlvbiBfX3dlYnBhY2tfcmVxdWlyZV9fKG1vZHVsZUlkKSB7XG5cbiBcdFx0Ly8gQ2hlY2sgaWYgbW9kdWxlIGlzIGluIGNhY2hlXG4gXHRcdGlmKGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdKVxuIFx0XHRcdHJldHVybiBpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXS5leHBvcnRzO1xuXG4gXHRcdC8vIENyZWF0ZSBhIG5ldyBtb2R1bGUgKGFuZCBwdXQgaXQgaW50byB0aGUgY2FjaGUpXG4gXHRcdHZhciBtb2R1bGUgPSBpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXSA9IHtcbiBcdFx0XHRpOiBtb2R1bGVJZCxcbiBcdFx0XHRsOiBmYWxzZSxcbiBcdFx0XHRleHBvcnRzOiB7fVxuIFx0XHR9O1xuXG4gXHRcdC8vIEV4ZWN1dGUgdGhlIG1vZHVsZSBmdW5jdGlvblxuIFx0XHRtb2R1bGVzW21vZHVsZUlkXS5jYWxsKG1vZHVsZS5leHBvcnRzLCBtb2R1bGUsIG1vZHVsZS5leHBvcnRzLCBfX3dlYnBhY2tfcmVxdWlyZV9fKTtcblxuIFx0XHQvLyBGbGFnIHRoZSBtb2R1bGUgYXMgbG9hZGVkXG4gXHRcdG1vZHVsZS5sID0gdHJ1ZTtcblxuIFx0XHQvLyBSZXR1cm4gdGhlIGV4cG9ydHMgb2YgdGhlIG1vZHVsZVxuIFx0XHRyZXR1cm4gbW9kdWxlLmV4cG9ydHM7XG4gXHR9XG5cblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGVzIG9iamVjdCAoX193ZWJwYWNrX21vZHVsZXNfXylcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubSA9IG1vZHVsZXM7XG5cbiBcdC8vIGV4cG9zZSB0aGUgbW9kdWxlIGNhY2hlXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmMgPSBpbnN0YWxsZWRNb2R1bGVzO1xuXG4gXHQvLyBpZGVudGl0eSBmdW5jdGlvbiBmb3IgY2FsbGluZyBoYXJtb255IGltcG9ydHMgd2l0aCB0aGUgY29ycmVjdCBjb250ZXh0XG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmkgPSBmdW5jdGlvbih2YWx1ZSkgeyByZXR1cm4gdmFsdWU7IH07XG5cbiBcdC8vIGRlZmluZSBnZXR0ZXIgZnVuY3Rpb24gZm9yIGhhcm1vbnkgZXhwb3J0c1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5kID0gZnVuY3Rpb24oZXhwb3J0cywgbmFtZSwgZ2V0dGVyKSB7XG4gXHRcdGlmKCFfX3dlYnBhY2tfcmVxdWlyZV9fLm8oZXhwb3J0cywgbmFtZSkpIHtcbiBcdFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgbmFtZSwge1xuIFx0XHRcdFx0Y29uZmlndXJhYmxlOiBmYWxzZSxcbiBcdFx0XHRcdGVudW1lcmFibGU6IHRydWUsXG4gXHRcdFx0XHRnZXQ6IGdldHRlclxuIFx0XHRcdH0pO1xuIFx0XHR9XG4gXHR9O1xuXG4gXHQvLyBnZXREZWZhdWx0RXhwb3J0IGZ1bmN0aW9uIGZvciBjb21wYXRpYmlsaXR5IHdpdGggbm9uLWhhcm1vbnkgbW9kdWxlc1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5uID0gZnVuY3Rpb24obW9kdWxlKSB7XG4gXHRcdHZhciBnZXR0ZXIgPSBtb2R1bGUgJiYgbW9kdWxlLl9fZXNNb2R1bGUgP1xuIFx0XHRcdGZ1bmN0aW9uIGdldERlZmF1bHQoKSB7IHJldHVybiBtb2R1bGVbJ2RlZmF1bHQnXTsgfSA6XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0TW9kdWxlRXhwb3J0cygpIHsgcmV0dXJuIG1vZHVsZTsgfTtcbiBcdFx0X193ZWJwYWNrX3JlcXVpcmVfXy5kKGdldHRlciwgJ2EnLCBnZXR0ZXIpO1xuIFx0XHRyZXR1cm4gZ2V0dGVyO1xuIFx0fTtcblxuIFx0Ly8gT2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm8gPSBmdW5jdGlvbihvYmplY3QsIHByb3BlcnR5KSB7IHJldHVybiBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwob2JqZWN0LCBwcm9wZXJ0eSk7IH07XG5cbiBcdC8vIF9fd2VicGFja19wdWJsaWNfcGF0aF9fXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLnAgPSBcIlwiO1xuXG4gXHQvLyBMb2FkIGVudHJ5IG1vZHVsZSBhbmQgcmV0dXJuIGV4cG9ydHNcbiBcdHJldHVybiBfX3dlYnBhY2tfcmVxdWlyZV9fKF9fd2VicGFja19yZXF1aXJlX18ucyA9IDcpO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIHdlYnBhY2svYm9vdHN0cmFwIDkzM2ZmN2Q1ZWQzOTNkYzYzYmNhIiwiY29uc3QgZHJvcGxhYkZpbHRlciA9IHtcbiAga2V5ZG93bjogZnVuY3Rpb24oZSl7XG4gICAgdmFyIGhpZGRlbkNvdW50ID0gMDtcbiAgICB2YXIgZGF0YUhpZGRlbkNvdW50ID0gMDtcblxuICAgIHZhciBsaXN0ID0gZS5kZXRhaWwuaG9vay5saXN0O1xuICAgIHZhciBkYXRhID0gbGlzdC5kYXRhO1xuICAgIHZhciB2YWx1ZSA9IGUuZGV0YWlsLmhvb2sudHJpZ2dlci52YWx1ZS50b0xvd2VyQ2FzZSgpO1xuICAgIHZhciBjb25maWcgPSBlLmRldGFpbC5ob29rLmNvbmZpZy5kcm9wbGFiRmlsdGVyO1xuICAgIHZhciBtYXRjaGVzID0gW107XG4gICAgdmFyIGZpbHRlckZ1bmN0aW9uO1xuICAgIC8vIHdpbGwgb25seSB3b3JrIG9uIGR5bmFtaWNhbGx5IHNldCBkYXRhXG4gICAgaWYoIWRhdGEpe1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIGlmIChjb25maWcgJiYgY29uZmlnLmZpbHRlckZ1bmN0aW9uICYmIHR5cGVvZiBjb25maWcuZmlsdGVyRnVuY3Rpb24gPT09ICdmdW5jdGlvbicpIHtcbiAgICAgIGZpbHRlckZ1bmN0aW9uID0gY29uZmlnLmZpbHRlckZ1bmN0aW9uO1xuICAgIH0gZWxzZSB7XG4gICAgICBmaWx0ZXJGdW5jdGlvbiA9IGZ1bmN0aW9uKG8pe1xuICAgICAgICAvLyBjaGVhcCBzdHJpbmcgc2VhcmNoXG4gICAgICAgIG8uZHJvcGxhYl9oaWRkZW4gPSBvW2NvbmZpZy50ZW1wbGF0ZV0udG9Mb3dlckNhc2UoKS5pbmRleE9mKHZhbHVlKSA9PT0gLTE7XG4gICAgICAgIHJldHVybiBvO1xuICAgICAgfTtcbiAgICB9XG5cbiAgICBkYXRhSGlkZGVuQ291bnQgPSBkYXRhLmZpbHRlcihmdW5jdGlvbihvKSB7XG4gICAgICByZXR1cm4gIW8uZHJvcGxhYl9oaWRkZW47XG4gICAgfSkubGVuZ3RoO1xuXG4gICAgbWF0Y2hlcyA9IGRhdGEubWFwKGZ1bmN0aW9uKG8pIHtcbiAgICAgIHJldHVybiBmaWx0ZXJGdW5jdGlvbihvLCB2YWx1ZSk7XG4gICAgfSk7XG5cbiAgICBoaWRkZW5Db3VudCA9IG1hdGNoZXMuZmlsdGVyKGZ1bmN0aW9uKG8pIHtcbiAgICAgIHJldHVybiAhby5kcm9wbGFiX2hpZGRlbjtcbiAgICB9KS5sZW5ndGg7XG5cbiAgICBpZiAoZGF0YUhpZGRlbkNvdW50ICE9PSBoaWRkZW5Db3VudCkge1xuICAgICAgbGlzdC5yZW5kZXIobWF0Y2hlcyk7XG4gICAgICBsaXN0LmN1cnJlbnRJbmRleCA9IDA7XG4gICAgfVxuICB9LFxuXG4gIGRlYm91bmNlS2V5ZG93bjogZnVuY3Rpb24gZGVib3VuY2VLZXlkb3duKGUpIHtcbiAgICBpZiAoW1xuICAgICAgMTMsIC8vIGVudGVyXG4gICAgICAxNiwgLy8gc2hpZnRcbiAgICAgIDE3LCAvLyBjdHJsXG4gICAgICAxOCwgLy8gYWx0XG4gICAgICAyMCwgLy8gY2FwcyBsb2NrXG4gICAgICAzNywgLy8gbGVmdCBhcnJvd1xuICAgICAgMzgsIC8vIHVwIGFycm93XG4gICAgICAzOSwgLy8gcmlnaHQgYXJyb3dcbiAgICAgIDQwLCAvLyBkb3duIGFycm93XG4gICAgICA5MSwgLy8gbGVmdCB3aW5kb3dcbiAgICAgIDkyLCAvLyByaWdodCB3aW5kb3dcbiAgICAgIDkzLCAvLyBzZWxlY3RcbiAgICBdLmluZGV4T2YoZS5kZXRhaWwud2hpY2ggfHwgZS5kZXRhaWwua2V5Q29kZSkgPiAtMSkgcmV0dXJuO1xuXG4gICAgaWYgKHRoaXMudGltZW91dCkgY2xlYXJUaW1lb3V0KHRoaXMudGltZW91dCk7XG4gICAgdGhpcy50aW1lb3V0ID0gc2V0VGltZW91dCh0aGlzLmtleWRvd24uYmluZCh0aGlzLCBlKSwgMjAwKTtcbiAgfSxcblxuICBpbml0OiBmdW5jdGlvbiBpbml0KGhvb2spIHtcbiAgICB2YXIgY29uZmlnID0gaG9vay5jb25maWcuZHJvcGxhYkZpbHRlcjtcblxuICAgIGlmICghY29uZmlnIHx8ICFjb25maWcudGVtcGxhdGUpIHJldHVybjtcblxuICAgIHRoaXMuaG9vayA9IGhvb2s7XG5cbiAgICB0aGlzLmV2ZW50V3JhcHBlciA9IHt9O1xuICAgIHRoaXMuZXZlbnRXcmFwcGVyLmRlYm91bmNlS2V5ZG93biA9IHRoaXMuZGVib3VuY2VLZXlkb3duLmJpbmQodGhpcyk7XG5cbiAgICB0aGlzLmhvb2sudHJpZ2dlci5hZGRFdmVudExpc3RlbmVyKCdrZXlkb3duLmRsJywgdGhpcy5ldmVudFdyYXBwZXIuZGVib3VuY2VLZXlkb3duKTtcbiAgICB0aGlzLmhvb2sudHJpZ2dlci5hZGRFdmVudExpc3RlbmVyKCdtb3VzZWRvd24uZGwnLCB0aGlzLmV2ZW50V3JhcHBlci5kZWJvdW5jZUtleWRvd24pO1xuICB9LFxuXG4gIGRlc3Ryb3k6IGZ1bmN0aW9uIGRlc3Ryb3koKSB7XG4gICAgdGhpcy5ob29rLnRyaWdnZXIucmVtb3ZlRXZlbnRMaXN0ZW5lcigna2V5ZG93bi5kbCcsIHRoaXMuZXZlbnRXcmFwcGVyLmRlYm91bmNlS2V5ZG93bik7XG4gICAgdGhpcy5ob29rLnRyaWdnZXIucmVtb3ZlRXZlbnRMaXN0ZW5lcignbW91c2Vkb3duLmRsJywgdGhpcy5ldmVudFdyYXBwZXIuZGVib3VuY2VLZXlkb3duKTtcblxuICAgIHZhciBkeW5hbWljTGlzdCA9IHRoaXMuaG9vay5saXN0Lmxpc3QucXVlcnlTZWxlY3RvcignW2RhdGEtZHluYW1pY10nKTtcbiAgICBpZiAodGhpcy5saXN0VGVtcGxhdGUgJiYgZHluYW1pY0xpc3QpIHtcbiAgICAgIGR5bmFtaWNMaXN0Lm91dGVySFRNTCA9IHRoaXMubGlzdFRlbXBsYXRlO1xuICAgIH1cbiAgfVxufTtcblxuZXhwb3J0IGRlZmF1bHQgZHJvcGxhYkZpbHRlcjtcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyAuL3NyYy9wbHVnaW5zL2ZpbHRlci9maWx0ZXIuanMiXSwic291cmNlUm9vdCI6IiJ9