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
/******/ 	return __webpack_require__(__webpack_require__.s = 12);
/******/ })
/************************************************************************/
/******/ ({

/***/ 12:
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
  },

  destroy: function destroy() {
    this.hook.trigger.removeEventListener('keydown.dl', this.eventWrapper.debounceKeydown);

    var dynamicList = this.hook.list.list.querySelector('[data-dynamic]');
    if (this.listTemplate && dynamicList) {
      dynamicList.outerHTML = this.listTemplate;
    }
  }
};

window.droplabFilter = droplabFilter;

exports.default = droplabFilter;

/***/ })

/******/ });
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAgZjM3NjcyYjdmNTI4YjQ3MmE0NGM/ZWM1ZioiLCJ3ZWJwYWNrOi8vLy4vc3JjL3BsdWdpbnMvZmlsdGVyLmpzIl0sIm5hbWVzIjpbImRyb3BsYWJGaWx0ZXIiLCJrZXlkb3duIiwiZSIsImhpZGRlbkNvdW50IiwiZGF0YUhpZGRlbkNvdW50IiwibGlzdCIsImRldGFpbCIsImhvb2siLCJkYXRhIiwidmFsdWUiLCJ0cmlnZ2VyIiwidG9Mb3dlckNhc2UiLCJjb25maWciLCJtYXRjaGVzIiwiZmlsdGVyRnVuY3Rpb24iLCJvIiwiZHJvcGxhYl9oaWRkZW4iLCJ0ZW1wbGF0ZSIsImluZGV4T2YiLCJmaWx0ZXIiLCJsZW5ndGgiLCJtYXAiLCJyZW5kZXIiLCJjdXJyZW50SW5kZXgiLCJkZWJvdW5jZUtleWRvd24iLCJ3aGljaCIsImtleUNvZGUiLCJ0aW1lb3V0IiwiY2xlYXJUaW1lb3V0Iiwic2V0VGltZW91dCIsImJpbmQiLCJpbml0IiwiZXZlbnRXcmFwcGVyIiwiYWRkRXZlbnRMaXN0ZW5lciIsImRlc3Ryb3kiLCJyZW1vdmVFdmVudExpc3RlbmVyIiwiZHluYW1pY0xpc3QiLCJxdWVyeVNlbGVjdG9yIiwibGlzdFRlbXBsYXRlIiwib3V0ZXJIVE1MIiwid2luZG93Il0sIm1hcHBpbmdzIjoiO0FBQUE7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTs7O0FBR0E7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0EsbURBQTJDLGNBQWM7O0FBRXpEO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsYUFBSztBQUNMO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0EsbUNBQTJCLDBCQUEwQixFQUFFO0FBQ3ZELHlDQUFpQyxlQUFlO0FBQ2hEO0FBQ0E7QUFDQTs7QUFF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QixZQUFMLEdBQW9CLEVBQXBCO0FBQ0EsU0FBS0EsWUFBTCxDQUFrQlIsZUFBbEIsR0FBb0MsS0FBS0EsZUFBTCxDQUFxQk0sSUFBckIsQ0FBMEIsSUFBMUIsQ0FBcEM7O0FBRUEsU0FBS3ZCLElBQUwsQ0FBVUcsT0FBVixDQUFrQnVCLGdCQUFsQixDQUFtQyxZQUFuQyxFQUFpRCxLQUFLRCxZQUFMLENBQWtCUixlQUFuRTtBQUNELEdBM0VtQjs7QUE2RXBCVSxXQUFTLFNBQVNBLE9BQVQsR0FBbUI7QUFDMUIsU0FBSzNCLElBQUwsQ0FBVUcsT0FBVixDQUFrQnlCLG1CQUFsQixDQUFzQyxZQUF0QyxFQUFvRCxLQUFLSCxZQUFMLENBQWtCUixlQUF0RTs7QUFFQSxRQUFJWSxjQUFjLEtBQUs3QixJQUFMLENBQVVGLElBQVYsQ0FBZUEsSUFBZixDQUFvQmdDLGFBQXBCLENBQWtDLGdCQUFsQyxDQUFsQjtBQUNBLFFBQUksS0FBS0MsWUFBTCxJQUFxQkYsV0FBekIsRUFBc0M7QUFDcENBLGtCQUFZRyxTQUFaLEdBQXdCLEtBQUtELFlBQTdCO0FBQ0Q7QUFDRjtBQXBGbUIsQ0FBdEI7O0FBdUZBRSxPQUFPeEMsYUFBUCxHQUF1QkEsYUFBdkI7O2tCQUVlQSxhIiwiZmlsZSI6Ii4vZGlzdC9wbHVnaW5zL2ZpbHRlci5qcyIsInNvdXJjZXNDb250ZW50IjpbIiBcdC8vIFRoZSBtb2R1bGUgY2FjaGVcbiBcdHZhciBpbnN0YWxsZWRNb2R1bGVzID0ge307XG5cbiBcdC8vIFRoZSByZXF1aXJlIGZ1bmN0aW9uXG4gXHRmdW5jdGlvbiBfX3dlYnBhY2tfcmVxdWlyZV9fKG1vZHVsZUlkKSB7XG5cbiBcdFx0Ly8gQ2hlY2sgaWYgbW9kdWxlIGlzIGluIGNhY2hlXG4gXHRcdGlmKGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdKVxuIFx0XHRcdHJldHVybiBpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXS5leHBvcnRzO1xuXG4gXHRcdC8vIENyZWF0ZSBhIG5ldyBtb2R1bGUgKGFuZCBwdXQgaXQgaW50byB0aGUgY2FjaGUpXG4gXHRcdHZhciBtb2R1bGUgPSBpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXSA9IHtcbiBcdFx0XHRpOiBtb2R1bGVJZCxcbiBcdFx0XHRsOiBmYWxzZSxcbiBcdFx0XHRleHBvcnRzOiB7fVxuIFx0XHR9O1xuXG4gXHRcdC8vIEV4ZWN1dGUgdGhlIG1vZHVsZSBmdW5jdGlvblxuIFx0XHRtb2R1bGVzW21vZHVsZUlkXS5jYWxsKG1vZHVsZS5leHBvcnRzLCBtb2R1bGUsIG1vZHVsZS5leHBvcnRzLCBfX3dlYnBhY2tfcmVxdWlyZV9fKTtcblxuIFx0XHQvLyBGbGFnIHRoZSBtb2R1bGUgYXMgbG9hZGVkXG4gXHRcdG1vZHVsZS5sID0gdHJ1ZTtcblxuIFx0XHQvLyBSZXR1cm4gdGhlIGV4cG9ydHMgb2YgdGhlIG1vZHVsZVxuIFx0XHRyZXR1cm4gbW9kdWxlLmV4cG9ydHM7XG4gXHR9XG5cblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGVzIG9iamVjdCAoX193ZWJwYWNrX21vZHVsZXNfXylcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubSA9IG1vZHVsZXM7XG5cbiBcdC8vIGV4cG9zZSB0aGUgbW9kdWxlIGNhY2hlXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmMgPSBpbnN0YWxsZWRNb2R1bGVzO1xuXG4gXHQvLyBpZGVudGl0eSBmdW5jdGlvbiBmb3IgY2FsbGluZyBoYXJtb255IGltcG9ydHMgd2l0aCB0aGUgY29ycmVjdCBjb250ZXh0XG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmkgPSBmdW5jdGlvbih2YWx1ZSkgeyByZXR1cm4gdmFsdWU7IH07XG5cbiBcdC8vIGRlZmluZSBnZXR0ZXIgZnVuY3Rpb24gZm9yIGhhcm1vbnkgZXhwb3J0c1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5kID0gZnVuY3Rpb24oZXhwb3J0cywgbmFtZSwgZ2V0dGVyKSB7XG4gXHRcdGlmKCFfX3dlYnBhY2tfcmVxdWlyZV9fLm8oZXhwb3J0cywgbmFtZSkpIHtcbiBcdFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgbmFtZSwge1xuIFx0XHRcdFx0Y29uZmlndXJhYmxlOiBmYWxzZSxcbiBcdFx0XHRcdGVudW1lcmFibGU6IHRydWUsXG4gXHRcdFx0XHRnZXQ6IGdldHRlclxuIFx0XHRcdH0pO1xuIFx0XHR9XG4gXHR9O1xuXG4gXHQvLyBnZXREZWZhdWx0RXhwb3J0IGZ1bmN0aW9uIGZvciBjb21wYXRpYmlsaXR5IHdpdGggbm9uLWhhcm1vbnkgbW9kdWxlc1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5uID0gZnVuY3Rpb24obW9kdWxlKSB7XG4gXHRcdHZhciBnZXR0ZXIgPSBtb2R1bGUgJiYgbW9kdWxlLl9fZXNNb2R1bGUgP1xuIFx0XHRcdGZ1bmN0aW9uIGdldERlZmF1bHQoKSB7IHJldHVybiBtb2R1bGVbJ2RlZmF1bHQnXTsgfSA6XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0TW9kdWxlRXhwb3J0cygpIHsgcmV0dXJuIG1vZHVsZTsgfTtcbiBcdFx0X193ZWJwYWNrX3JlcXVpcmVfXy5kKGdldHRlciwgJ2EnLCBnZXR0ZXIpO1xuIFx0XHRyZXR1cm4gZ2V0dGVyO1xuIFx0fTtcblxuIFx0Ly8gT2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm8gPSBmdW5jdGlvbihvYmplY3QsIHByb3BlcnR5KSB7IHJldHVybiBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwob2JqZWN0LCBwcm9wZXJ0eSk7IH07XG5cbiBcdC8vIF9fd2VicGFja19wdWJsaWNfcGF0aF9fXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLnAgPSBcIlwiO1xuXG4gXHQvLyBMb2FkIGVudHJ5IG1vZHVsZSBhbmQgcmV0dXJuIGV4cG9ydHNcbiBcdHJldHVybiBfX3dlYnBhY2tfcmVxdWlyZV9fKF9fd2VicGFja19yZXF1aXJlX18ucyA9IDEyKTtcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyB3ZWJwYWNrL2Jvb3RzdHJhcCBmMzc2NzJiN2Y1MjhiNDcyYTQ0YyIsImNvbnN0IGRyb3BsYWJGaWx0ZXIgPSB7XG4gIGtleWRvd246IGZ1bmN0aW9uKGUpe1xuICAgIHZhciBoaWRkZW5Db3VudCA9IDA7XG4gICAgdmFyIGRhdGFIaWRkZW5Db3VudCA9IDA7XG5cbiAgICB2YXIgbGlzdCA9IGUuZGV0YWlsLmhvb2subGlzdDtcbiAgICB2YXIgZGF0YSA9IGxpc3QuZGF0YTtcbiAgICB2YXIgdmFsdWUgPSBlLmRldGFpbC5ob29rLnRyaWdnZXIudmFsdWUudG9Mb3dlckNhc2UoKTtcbiAgICB2YXIgY29uZmlnID0gZS5kZXRhaWwuaG9vay5jb25maWcuZHJvcGxhYkZpbHRlcjtcbiAgICB2YXIgbWF0Y2hlcyA9IFtdO1xuICAgIHZhciBmaWx0ZXJGdW5jdGlvbjtcbiAgICAvLyB3aWxsIG9ubHkgd29yayBvbiBkeW5hbWljYWxseSBzZXQgZGF0YVxuICAgIGlmKCFkYXRhKXtcbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICBpZiAoY29uZmlnICYmIGNvbmZpZy5maWx0ZXJGdW5jdGlvbiAmJiB0eXBlb2YgY29uZmlnLmZpbHRlckZ1bmN0aW9uID09PSAnZnVuY3Rpb24nKSB7XG4gICAgICBmaWx0ZXJGdW5jdGlvbiA9IGNvbmZpZy5maWx0ZXJGdW5jdGlvbjtcbiAgICB9IGVsc2Uge1xuICAgICAgZmlsdGVyRnVuY3Rpb24gPSBmdW5jdGlvbihvKXtcbiAgICAgICAgLy8gY2hlYXAgc3RyaW5nIHNlYXJjaFxuICAgICAgICBvLmRyb3BsYWJfaGlkZGVuID0gb1tjb25maWcudGVtcGxhdGVdLnRvTG93ZXJDYXNlKCkuaW5kZXhPZih2YWx1ZSkgPT09IC0xO1xuICAgICAgICByZXR1cm4gbztcbiAgICAgIH07XG4gICAgfVxuXG4gICAgZGF0YUhpZGRlbkNvdW50ID0gZGF0YS5maWx0ZXIoZnVuY3Rpb24obykge1xuICAgICAgcmV0dXJuICFvLmRyb3BsYWJfaGlkZGVuO1xuICAgIH0pLmxlbmd0aDtcblxuICAgIG1hdGNoZXMgPSBkYXRhLm1hcChmdW5jdGlvbihvKSB7XG4gICAgICByZXR1cm4gZmlsdGVyRnVuY3Rpb24obywgdmFsdWUpO1xuICAgIH0pO1xuXG4gICAgaGlkZGVuQ291bnQgPSBtYXRjaGVzLmZpbHRlcihmdW5jdGlvbihvKSB7XG4gICAgICByZXR1cm4gIW8uZHJvcGxhYl9oaWRkZW47XG4gICAgfSkubGVuZ3RoO1xuXG4gICAgaWYgKGRhdGFIaWRkZW5Db3VudCAhPT0gaGlkZGVuQ291bnQpIHtcbiAgICAgIGxpc3QucmVuZGVyKG1hdGNoZXMpO1xuICAgICAgbGlzdC5jdXJyZW50SW5kZXggPSAwO1xuICAgIH1cbiAgfSxcblxuICBkZWJvdW5jZUtleWRvd246IGZ1bmN0aW9uIGRlYm91bmNlS2V5ZG93bihlKSB7XG4gICAgaWYgKFtcbiAgICAgIDEzLCAvLyBlbnRlclxuICAgICAgMTYsIC8vIHNoaWZ0XG4gICAgICAxNywgLy8gY3RybFxuICAgICAgMTgsIC8vIGFsdFxuICAgICAgMjAsIC8vIGNhcHMgbG9ja1xuICAgICAgMzcsIC8vIGxlZnQgYXJyb3dcbiAgICAgIDM4LCAvLyB1cCBhcnJvd1xuICAgICAgMzksIC8vIHJpZ2h0IGFycm93XG4gICAgICA0MCwgLy8gZG93biBhcnJvd1xuICAgICAgOTEsIC8vIGxlZnQgd2luZG93XG4gICAgICA5MiwgLy8gcmlnaHQgd2luZG93XG4gICAgICA5MywgLy8gc2VsZWN0XG4gICAgXS5pbmRleE9mKGUuZGV0YWlsLndoaWNoIHx8IGUuZGV0YWlsLmtleUNvZGUpID4gLTEpIHJldHVybjtcblxuICAgIGlmICh0aGlzLnRpbWVvdXQpIGNsZWFyVGltZW91dCh0aGlzLnRpbWVvdXQpO1xuICAgIHRoaXMudGltZW91dCA9IHNldFRpbWVvdXQodGhpcy5rZXlkb3duLmJpbmQodGhpcywgZSksIDIwMCk7XG4gIH0sXG5cbiAgaW5pdDogZnVuY3Rpb24gaW5pdChob29rKSB7XG4gICAgdmFyIGNvbmZpZyA9IGhvb2suY29uZmlnLmRyb3BsYWJGaWx0ZXI7XG5cbiAgICBpZiAoIWNvbmZpZyB8fCAhY29uZmlnLnRlbXBsYXRlKSByZXR1cm47XG5cbiAgICB0aGlzLmhvb2sgPSBob29rO1xuXG4gICAgdGhpcy5ldmVudFdyYXBwZXIgPSB7fTtcbiAgICB0aGlzLmV2ZW50V3JhcHBlci5kZWJvdW5jZUtleWRvd24gPSB0aGlzLmRlYm91bmNlS2V5ZG93bi5iaW5kKHRoaXMpO1xuXG4gICAgdGhpcy5ob29rLnRyaWdnZXIuYWRkRXZlbnRMaXN0ZW5lcigna2V5ZG93bi5kbCcsIHRoaXMuZXZlbnRXcmFwcGVyLmRlYm91bmNlS2V5ZG93bik7XG4gIH0sXG5cbiAgZGVzdHJveTogZnVuY3Rpb24gZGVzdHJveSgpIHtcbiAgICB0aGlzLmhvb2sudHJpZ2dlci5yZW1vdmVFdmVudExpc3RlbmVyKCdrZXlkb3duLmRsJywgdGhpcy5ldmVudFdyYXBwZXIuZGVib3VuY2VLZXlkb3duKTtcblxuICAgIHZhciBkeW5hbWljTGlzdCA9IHRoaXMuaG9vay5saXN0Lmxpc3QucXVlcnlTZWxlY3RvcignW2RhdGEtZHluYW1pY10nKTtcbiAgICBpZiAodGhpcy5saXN0VGVtcGxhdGUgJiYgZHluYW1pY0xpc3QpIHtcbiAgICAgIGR5bmFtaWNMaXN0Lm91dGVySFRNTCA9IHRoaXMubGlzdFRlbXBsYXRlO1xuICAgIH1cbiAgfVxufTtcblxud2luZG93LmRyb3BsYWJGaWx0ZXIgPSBkcm9wbGFiRmlsdGVyO1xuXG5leHBvcnQgZGVmYXVsdCBkcm9wbGFiRmlsdGVyO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL3BsdWdpbnMvZmlsdGVyLmpzIl0sInNvdXJjZVJvb3QiOiIifQ==