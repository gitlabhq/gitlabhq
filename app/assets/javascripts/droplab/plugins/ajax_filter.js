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
/******/ 	return __webpack_require__(__webpack_require__.s = 6);
/******/ })
/************************************************************************/
/******/ ({

/***/ 6:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var droplabAjaxFilter = {
  init: function init(hook) {
    this.destroyed = false;
    this.hook = hook;
    this.notLoading();

    this.eventWrapper = {};
    this.eventWrapper.debounceTrigger = this.debounceTrigger.bind(this);
    this.hook.trigger.addEventListener('keydown.dl', this.eventWrapper.debounceTrigger);
    this.hook.trigger.addEventListener('focus', this.eventWrapper.debounceTrigger);

    this.trigger(true);
  },

  notLoading: function notLoading() {
    this.loading = false;
  },

  debounceTrigger: function debounceTrigger(e) {
    var NON_CHARACTER_KEYS = [16, 17, 18, 20, 37, 38, 39, 40, 91, 93];
    var invalidKeyPressed = NON_CHARACTER_KEYS.indexOf(e.detail.which || e.detail.keyCode) > -1;
    var focusEvent = e.type === 'focus';
    if (invalidKeyPressed || this.loading) {
      return;
    }
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
    this.timeout = setTimeout(this.trigger.bind(this, focusEvent), 200);
  },

  trigger: function trigger(getEntireList) {
    var config = this.hook.config.droplabAjaxFilter;
    var searchValue = this.trigger.value;
    if (!config || !config.endpoint || !config.searchKey) {
      return;
    }
    if (config.searchValueFunction) {
      searchValue = config.searchValueFunction();
    }
    if (config.loadingTemplate && this.hook.list.data === undefined || this.hook.list.data.length === 0) {
      var dynamicList = this.hook.list.list.querySelector('[data-dynamic]');
      var loadingTemplate = document.createElement('div');
      loadingTemplate.innerHTML = config.loadingTemplate;
      loadingTemplate.setAttribute('data-loading-template', true);
      this.listTemplate = dynamicList.outerHTML;
      dynamicList.outerHTML = loadingTemplate.outerHTML;
    }
    if (getEntireList) {
      searchValue = '';
    }
    if (config.searchKey === searchValue) {
      return this.list.show();
    }
    this.loading = true;
    var params = config.params || {};
    params[config.searchKey] = searchValue;
    var self = this;
    self.cache = self.cache || {};
    var url = config.endpoint + this.buildParams(params);
    var urlCachedData = self.cache[url];
    if (urlCachedData) {
      self._loadData(urlCachedData, config, self);
    } else {
      this._loadUrlData(url).then(function (data) {
        self._loadData(data, config, self);
      });
    }
  },

  _loadUrlData: function _loadUrlData(url) {
    var self = this;
    return new Promise(function (resolve, reject) {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', url, true);
      xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
          if (xhr.status === 200) {
            var data = JSON.parse(xhr.responseText);
            self.cache[url] = data;
            return resolve(data);
          } else {
            return reject([xhr.responseText, xhr.status]);
          }
        }
      };
      xhr.send();
    });
  },

  _loadData: function _loadData(data, config, self) {
    var list = self.hook.list;
    if (config.loadingTemplate && list.data === undefined || list.data.length === 0) {
      var dataLoadingTemplate = list.list.querySelector('[data-loading-template]');
      if (dataLoadingTemplate) {
        dataLoadingTemplate.outerHTML = self.listTemplate;
      }
    }
    if (!self.destroyed) {
      var hookListChildren = list.list.children;
      var onlyDynamicList = hookListChildren.length === 1 && hookListChildren[0].hasAttribute('data-dynamic');
      if (onlyDynamicList && data.length === 0) {
        list.hide();
      }
      list.setData.call(list, data);
    }
    self.notLoading();
    list.currentIndex = 0;
  },

  buildParams: function buildParams(params) {
    if (!params) return '';
    var paramsArray = Object.keys(params).map(function (param) {
      return param + '=' + (params[param] || '');
    });
    return '?' + paramsArray.join('&');
  },

  destroy: function destroy() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    this.destroyed = true;
    this.hook.trigger.removeEventListener('keydown.dl', this.eventWrapper.debounceTrigger);
    this.hook.trigger.removeEventListener('focus', this.eventWrapper.debounceTrigger);
  }
};

exports.default = droplabAjaxFilter;

/***/ })

/******/ });
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAgOTMzZmY3ZDVlZDM5M2RjNjNiY2E/MGFiZioqKioqKioiLCJ3ZWJwYWNrOi8vLy4vc3JjL3BsdWdpbnMvYWpheF9maWx0ZXIvYWpheF9maWx0ZXIuanM/YzNlNSJdLCJuYW1lcyI6WyJkcm9wbGFiQWpheEZpbHRlciIsImluaXQiLCJob29rIiwiZGVzdHJveWVkIiwibm90TG9hZGluZyIsImV2ZW50V3JhcHBlciIsImRlYm91bmNlVHJpZ2dlciIsImJpbmQiLCJ0cmlnZ2VyIiwiYWRkRXZlbnRMaXN0ZW5lciIsImxvYWRpbmciLCJlIiwiTk9OX0NIQVJBQ1RFUl9LRVlTIiwiaW52YWxpZEtleVByZXNzZWQiLCJpbmRleE9mIiwiZGV0YWlsIiwid2hpY2giLCJrZXlDb2RlIiwiZm9jdXNFdmVudCIsInR5cGUiLCJ0aW1lb3V0IiwiY2xlYXJUaW1lb3V0Iiwic2V0VGltZW91dCIsImdldEVudGlyZUxpc3QiLCJjb25maWciLCJzZWFyY2hWYWx1ZSIsInZhbHVlIiwiZW5kcG9pbnQiLCJzZWFyY2hLZXkiLCJzZWFyY2hWYWx1ZUZ1bmN0aW9uIiwibG9hZGluZ1RlbXBsYXRlIiwibGlzdCIsImRhdGEiLCJ1bmRlZmluZWQiLCJsZW5ndGgiLCJkeW5hbWljTGlzdCIsInF1ZXJ5U2VsZWN0b3IiLCJkb2N1bWVudCIsImNyZWF0ZUVsZW1lbnQiLCJpbm5lckhUTUwiLCJzZXRBdHRyaWJ1dGUiLCJsaXN0VGVtcGxhdGUiLCJvdXRlckhUTUwiLCJzaG93IiwicGFyYW1zIiwic2VsZiIsImNhY2hlIiwidXJsIiwiYnVpbGRQYXJhbXMiLCJ1cmxDYWNoZWREYXRhIiwiX2xvYWREYXRhIiwiX2xvYWRVcmxEYXRhIiwidGhlbiIsIlByb21pc2UiLCJyZXNvbHZlIiwicmVqZWN0IiwieGhyIiwiWE1MSHR0cFJlcXVlc3QiLCJvcGVuIiwib25yZWFkeXN0YXRlY2hhbmdlIiwicmVhZHlTdGF0ZSIsIkRPTkUiLCJzdGF0dXMiLCJKU09OIiwicGFyc2UiLCJyZXNwb25zZVRleHQiLCJzZW5kIiwiZGF0YUxvYWRpbmdUZW1wbGF0ZSIsImhvb2tMaXN0Q2hpbGRyZW4iLCJjaGlsZHJlbiIsIm9ubHlEeW5hbWljTGlzdCIsImhhc0F0dHJpYnV0ZSIsImhpZGUiLCJzZXREYXRhIiwiY2FsbCIsImN1cnJlbnRJbmRleCIsInBhcmFtc0FycmF5IiwiT2JqZWN0Iiwia2V5cyIsIm1hcCIsInBhcmFtIiwiam9pbiIsImRlc3Ryb3kiLCJyZW1vdmVFdmVudExpc3RlbmVyIl0sIm1hcHBpbmdzIjoiO0FBQUE7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0E7QUFDQTs7O0FBR0E7QUFDQTs7QUFFQTtBQUNBOztBQUVBO0FBQ0EsbURBQTJDLGNBQWM7O0FBRXpEO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsYUFBSztBQUNMO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0EsbUNBQTJCLDBCQUEwQixFQUFFO0FBQ3ZELHlDQUFpQyxlQUFlO0FBQ2hEO0FBQ0E7QUFDQTs7QUFFQTtBQUNBLDhEQUFzRCwrREFBK0Q7O0FBRXJIO0FBQ0E7O0FBRUE7QUFDQTs7Ozs7Ozs7Ozs7Ozs7QUNoRUEsSUFBTUEsb0JBQW9CO0FBQ3hCQyxRQUFNLGNBQVNDLElBQVQsRUFBZTtBQUNuQixTQUFLQyxTQUFMLEdBQWlCLEtBQWpCO0FBQ0EsU0FBS0QsSUFBTCxHQUFZQSxJQUFaO0FBQ0EsU0FBS0UsVUFBTDs7QUFFQSxTQUFLQyxZQUFMLEdBQW9CLEVBQXBCO0FBQ0EsU0FBS0EsWUFBTCxDQUFrQkMsZUFBbEIsR0FBb0MsS0FBS0EsZUFBTCxDQUFxQkMsSUFBckIsQ0FBMEIsSUFBMUIsQ0FBcEM7QUFDQSxTQUFLTCxJQUFMLENBQVVNLE9BQVYsQ0FBa0JDLGdCQUFsQixDQUFtQyxZQUFuQyxFQUFpRCxLQUFLSixZQUFMLENB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QUFnQjtBQUN4RCxhQUFPQSxRQUFRLEdBQVIsSUFBZXBDLE9BQU9vQyxLQUFQLEtBQWlCLEVBQWhDLENBQVA7QUFDRCxLQUZpQixDQUFsQjtBQUdBLFdBQU8sTUFBTUosWUFBWUssSUFBWixDQUFpQixHQUFqQixDQUFiO0FBQ0QsR0F2SHVCOztBQXlIeEJDLFdBQVMsU0FBU0EsT0FBVCxHQUFtQjtBQUMxQixRQUFJLEtBQUs5RCxPQUFULEVBQWtCO0FBQ2hCQyxtQkFBYSxLQUFLRCxPQUFsQjtBQUNEOztBQUVELFNBQUtqQixTQUFMLEdBQWlCLElBQWpCO0FBQ0EsU0FBS0QsSUFBTCxDQUFVTSxPQUFWLENBQWtCMkUsbUJBQWxCLENBQXNDLFlBQXRDLEVBQW9ELEtBQUs5RSxZQUFMLENBQWtCQyxlQUF0RTtBQUNBLFNBQUtKLElBQUwsQ0FBVU0sT0FBVixDQUFrQjJFLG1CQUFsQixDQUFzQyxPQUF0QyxFQUErQyxLQUFLOUUsWUFBTCxDQUFrQkMsZUFBakU7QUFDRDtBQWpJdUIsQ0FBMUI7O2tCQW9JZU4saUIiLCJmaWxlIjoiLi9kaXN0L3BsdWdpbnMvYWpheF9maWx0ZXIuanMiLCJzb3VyY2VzQ29udGVudCI6WyIgXHQvLyBUaGUgbW9kdWxlIGNhY2hlXG4gXHR2YXIgaW5zdGFsbGVkTW9kdWxlcyA9IHt9O1xuXG4gXHQvLyBUaGUgcmVxdWlyZSBmdW5jdGlvblxuIFx0ZnVuY3Rpb24gX193ZWJwYWNrX3JlcXVpcmVfXyhtb2R1bGVJZCkge1xuXG4gXHRcdC8vIENoZWNrIGlmIG1vZHVsZSBpcyBpbiBjYWNoZVxuIFx0XHRpZihpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXSlcbiBcdFx0XHRyZXR1cm4gaW5zdGFsbGVkTW9kdWxlc1ttb2R1bGVJZF0uZXhwb3J0cztcblxuIFx0XHQvLyBDcmVhdGUgYSBuZXcgbW9kdWxlIChhbmQgcHV0IGl0IGludG8gdGhlIGNhY2hlKVxuIFx0XHR2YXIgbW9kdWxlID0gaW5zdGFsbGVkTW9kdWxlc1ttb2R1bGVJZF0gPSB7XG4gXHRcdFx0aTogbW9kdWxlSWQsXG4gXHRcdFx0bDogZmFsc2UsXG4gXHRcdFx0ZXhwb3J0czoge31cbiBcdFx0fTtcblxuIFx0XHQvLyBFeGVjdXRlIHRoZSBtb2R1bGUgZnVuY3Rpb25cbiBcdFx0bW9kdWxlc1ttb2R1bGVJZF0uY2FsbChtb2R1bGUuZXhwb3J0cywgbW9kdWxlLCBtb2R1bGUuZXhwb3J0cywgX193ZWJwYWNrX3JlcXVpcmVfXyk7XG5cbiBcdFx0Ly8gRmxhZyB0aGUgbW9kdWxlIGFzIGxvYWRlZFxuIFx0XHRtb2R1bGUubCA9IHRydWU7XG5cbiBcdFx0Ly8gUmV0dXJuIHRoZSBleHBvcnRzIG9mIHRoZSBtb2R1bGVcbiBcdFx0cmV0dXJuIG1vZHVsZS5leHBvcnRzO1xuIFx0fVxuXG5cbiBcdC8vIGV4cG9zZSB0aGUgbW9kdWxlcyBvYmplY3QgKF9fd2VicGFja19tb2R1bGVzX18pXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm0gPSBtb2R1bGVzO1xuXG4gXHQvLyBleHBvc2UgdGhlIG1vZHVsZSBjYWNoZVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5jID0gaW5zdGFsbGVkTW9kdWxlcztcblxuIFx0Ly8gaWRlbnRpdHkgZnVuY3Rpb24gZm9yIGNhbGxpbmcgaGFybW9ueSBpbXBvcnRzIHdpdGggdGhlIGNvcnJlY3QgY29udGV4dFxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5pID0gZnVuY3Rpb24odmFsdWUpIHsgcmV0dXJuIHZhbHVlOyB9O1xuXG4gXHQvLyBkZWZpbmUgZ2V0dGVyIGZ1bmN0aW9uIGZvciBoYXJtb255IGV4cG9ydHNcbiBcdF9fd2VicGFja19yZXF1aXJlX18uZCA9IGZ1bmN0aW9uKGV4cG9ydHMsIG5hbWUsIGdldHRlcikge1xuIFx0XHRpZighX193ZWJwYWNrX3JlcXVpcmVfXy5vKGV4cG9ydHMsIG5hbWUpKSB7XG4gXHRcdFx0T2JqZWN0LmRlZmluZVByb3BlcnR5KGV4cG9ydHMsIG5hbWUsIHtcbiBcdFx0XHRcdGNvbmZpZ3VyYWJsZTogZmFsc2UsXG4gXHRcdFx0XHRlbnVtZXJhYmxlOiB0cnVlLFxuIFx0XHRcdFx0Z2V0OiBnZXR0ZXJcbiBcdFx0XHR9KTtcbiBcdFx0fVxuIFx0fTtcblxuIFx0Ly8gZ2V0RGVmYXVsdEV4cG9ydCBmdW5jdGlvbiBmb3IgY29tcGF0aWJpbGl0eSB3aXRoIG5vbi1oYXJtb255IG1vZHVsZXNcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubiA9IGZ1bmN0aW9uKG1vZHVsZSkge1xuIFx0XHR2YXIgZ2V0dGVyID0gbW9kdWxlICYmIG1vZHVsZS5fX2VzTW9kdWxlID9cbiBcdFx0XHRmdW5jdGlvbiBnZXREZWZhdWx0KCkgeyByZXR1cm4gbW9kdWxlWydkZWZhdWx0J107IH0gOlxuIFx0XHRcdGZ1bmN0aW9uIGdldE1vZHVsZUV4cG9ydHMoKSB7IHJldHVybiBtb2R1bGU7IH07XG4gXHRcdF9fd2VicGFja19yZXF1aXJlX18uZChnZXR0ZXIsICdhJywgZ2V0dGVyKTtcbiBcdFx0cmV0dXJuIGdldHRlcjtcbiBcdH07XG5cbiBcdC8vIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbFxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5vID0gZnVuY3Rpb24ob2JqZWN0LCBwcm9wZXJ0eSkgeyByZXR1cm4gT2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsKG9iamVjdCwgcHJvcGVydHkpOyB9O1xuXG4gXHQvLyBfX3dlYnBhY2tfcHVibGljX3BhdGhfX1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5wID0gXCJcIjtcblxuIFx0Ly8gTG9hZCBlbnRyeSBtb2R1bGUgYW5kIHJldHVybiBleHBvcnRzXG4gXHRyZXR1cm4gX193ZWJwYWNrX3JlcXVpcmVfXyhfX3dlYnBhY2tfcmVxdWlyZV9fLnMgPSA2KTtcblxuXG5cbi8vIFdFQlBBQ0sgRk9PVEVSIC8vXG4vLyB3ZWJwYWNrL2Jvb3RzdHJhcCA5MzNmZjdkNWVkMzkzZGM2M2JjYSIsImNvbnN0IGRyb3BsYWJBamF4RmlsdGVyID0ge1xuICBpbml0OiBmdW5jdGlvbihob29rKSB7XG4gICAgdGhpcy5kZXN0cm95ZWQgPSBmYWxzZTtcbiAgICB0aGlzLmhvb2sgPSBob29rO1xuICAgIHRoaXMubm90TG9hZGluZygpO1xuXG4gICAgdGhpcy5ldmVudFdyYXBwZXIgPSB7fTtcbiAgICB0aGlzLmV2ZW50V3JhcHBlci5kZWJvdW5jZVRyaWdnZXIgPSB0aGlzLmRlYm91bmNlVHJpZ2dlci5iaW5kKHRoaXMpO1xuICAgIHRoaXMuaG9vay50cmlnZ2VyLmFkZEV2ZW50TGlzdGVuZXIoJ2tleWRvd24uZGwnLCB0aGlzLmV2ZW50V3JhcHBlci5kZWJvdW5jZVRyaWdnZXIpO1xuICAgIHRoaXMuaG9vay50cmlnZ2VyLmFkZEV2ZW50TGlzdGVuZXIoJ2ZvY3VzJywgdGhpcy5ldmVudFdyYXBwZXIuZGVib3VuY2VUcmlnZ2VyKTtcblxuICAgIHRoaXMudHJpZ2dlcih0cnVlKTtcbiAgfSxcblxuICBub3RMb2FkaW5nOiBmdW5jdGlvbiBub3RMb2FkaW5nKCkge1xuICAgIHRoaXMubG9hZGluZyA9IGZhbHNlO1xuICB9LFxuXG4gIGRlYm91bmNlVHJpZ2dlcjogZnVuY3Rpb24gZGVib3VuY2VUcmlnZ2VyKGUpIHtcbiAgICB2YXIgTk9OX0NIQVJBQ1RFUl9LRVlTID0gWzE2LCAxNywgMTgsIDIwLCAzNywgMzgsIDM5LCA0MCwgOTEsIDkzXTtcbiAgICB2YXIgaW52YWxpZEtleVByZXNzZWQgPSBOT05fQ0hBUkFDVEVSX0tFWVMuaW5kZXhPZihlLmRldGFpbC53aGljaCB8fCBlLmRldGFpbC5rZXlDb2RlKSA+IC0xO1xuICAgIHZhciBmb2N1c0V2ZW50ID0gZS50eXBlID09PSAnZm9jdXMnO1xuICAgIGlmIChpbnZhbGlkS2V5UHJlc3NlZCB8fCB0aGlzLmxvYWRpbmcpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgaWYgKHRoaXMudGltZW91dCkge1xuICAgICAgY2xlYXJUaW1lb3V0KHRoaXMudGltZW91dCk7XG4gICAgfVxuICAgIHRoaXMudGltZW91dCA9IHNldFRpbWVvdXQodGhpcy50cmlnZ2VyLmJpbmQodGhpcywgZm9jdXNFdmVudCksIDIwMCk7XG4gIH0sXG5cbiAgdHJpZ2dlcjogZnVuY3Rpb24gdHJpZ2dlcihnZXRFbnRpcmVMaXN0KSB7XG4gICAgdmFyIGNvbmZpZyA9IHRoaXMuaG9vay5jb25maWcuZHJvcGxhYkFqYXhGaWx0ZXI7XG4gICAgdmFyIHNlYXJjaFZhbHVlID0gdGhpcy50cmlnZ2VyLnZhbHVlO1xuICAgIGlmICghY29uZmlnIHx8ICFjb25maWcuZW5kcG9pbnQgfHwgIWNvbmZpZy5zZWFyY2hLZXkpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgaWYgKGNvbmZpZy5zZWFyY2hWYWx1ZUZ1bmN0aW9uKSB7XG4gICAgICBzZWFyY2hWYWx1ZSA9IGNvbmZpZy5zZWFyY2hWYWx1ZUZ1bmN0aW9uKCk7XG4gICAgfVxuICAgIGlmIChjb25maWcubG9hZGluZ1RlbXBsYXRlICYmIHRoaXMuaG9vay5saXN0LmRhdGEgPT09IHVuZGVmaW5lZCB8fFxuICAgICAgdGhpcy5ob29rLmxpc3QuZGF0YS5sZW5ndGggPT09IDApIHtcbiAgICAgIHZhciBkeW5hbWljTGlzdCA9IHRoaXMuaG9vay5saXN0Lmxpc3QucXVlcnlTZWxlY3RvcignW2RhdGEtZHluYW1pY10nKTtcbiAgICAgIHZhciBsb2FkaW5nVGVtcGxhdGUgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCdkaXYnKTtcbiAgICAgIGxvYWRpbmdUZW1wbGF0ZS5pbm5lckhUTUwgPSBjb25maWcubG9hZGluZ1RlbXBsYXRlO1xuICAgICAgbG9hZGluZ1RlbXBsYXRlLnNldEF0dHJpYnV0ZSgnZGF0YS1sb2FkaW5nLXRlbXBsYXRlJywgdHJ1ZSk7XG4gICAgICB0aGlzLmxpc3RUZW1wbGF0ZSA9IGR5bmFtaWNMaXN0Lm91dGVySFRNTDtcbiAgICAgIGR5bmFtaWNMaXN0Lm91dGVySFRNTCA9IGxvYWRpbmdUZW1wbGF0ZS5vdXRlckhUTUw7XG4gICAgfVxuICAgIGlmIChnZXRFbnRpcmVMaXN0KSB7XG4gICAgICBzZWFyY2hWYWx1ZSA9ICcnO1xuICAgIH1cbiAgICBpZiAoY29uZmlnLnNlYXJjaEtleSA9PT0gc2VhcmNoVmFsdWUpIHtcbiAgICAgIHJldHVybiB0aGlzLmxpc3Quc2hvdygpO1xuICAgIH1cbiAgICB0aGlzLmxvYWRpbmcgPSB0cnVlO1xuICAgIHZhciBwYXJhbXMgPSBjb25maWcucGFyYW1zIHx8IHt9O1xuICAgIHBhcmFtc1tjb25maWcuc2VhcmNoS2V5XSA9IHNlYXJjaFZhbHVlO1xuICAgIHZhciBzZWxmID0gdGhpcztcbiAgICBzZWxmLmNhY2hlID0gc2VsZi5jYWNoZSB8fCB7fTtcbiAgICB2YXIgdXJsID0gY29uZmlnLmVuZHBvaW50ICsgdGhpcy5idWlsZFBhcmFtcyhwYXJhbXMpO1xuICAgIHZhciB1cmxDYWNoZWREYXRhID0gc2VsZi5jYWNoZVt1cmxdO1xuICAgIGlmICh1cmxDYWNoZWREYXRhKSB7XG4gICAgICBzZWxmLl9sb2FkRGF0YSh1cmxDYWNoZWREYXRhLCBjb25maWcsIHNlbGYpO1xuICAgIH0gZWxzZSB7XG4gICAgICB0aGlzLl9sb2FkVXJsRGF0YSh1cmwpXG4gICAgICAgIC50aGVuKGZ1bmN0aW9uKGRhdGEpIHtcbiAgICAgICAgICBzZWxmLl9sb2FkRGF0YShkYXRhLCBjb25maWcsIHNlbGYpO1xuICAgICAgICB9KTtcbiAgICB9XG4gIH0sXG5cbiAgX2xvYWRVcmxEYXRhOiBmdW5jdGlvbiBfbG9hZFVybERhdGEodXJsKSB7XG4gICAgdmFyIHNlbGYgPSB0aGlzO1xuICAgIHJldHVybiBuZXcgUHJvbWlzZShmdW5jdGlvbihyZXNvbHZlLCByZWplY3QpIHtcbiAgICAgIHZhciB4aHIgPSBuZXcgWE1MSHR0cFJlcXVlc3Q7XG4gICAgICB4aHIub3BlbignR0VUJywgdXJsLCB0cnVlKTtcbiAgICAgIHhoci5vbnJlYWR5c3RhdGVjaGFuZ2UgPSBmdW5jdGlvbiAoKSB7XG4gICAgICAgIGlmKHhoci5yZWFkeVN0YXRlID09PSBYTUxIdHRwUmVxdWVzdC5ET05FKSB7XG4gICAgICAgICAgaWYgKHhoci5zdGF0dXMgPT09IDIwMCkge1xuICAgICAgICAgICAgdmFyIGRhdGEgPSBKU09OLnBhcnNlKHhoci5yZXNwb25zZVRleHQpO1xuICAgICAgICAgICAgc2VsZi5jYWNoZVt1cmxdID0gZGF0YTtcbiAgICAgICAgICAgIHJldHVybiByZXNvbHZlKGRhdGEpO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICByZXR1cm4gcmVqZWN0KFt4aHIucmVzcG9uc2VUZXh0LCB4aHIuc3RhdHVzXSk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9O1xuICAgICAgeGhyLnNlbmQoKTtcbiAgICB9KTtcbiAgfSxcblxuICBfbG9hZERhdGE6IGZ1bmN0aW9uIF9sb2FkRGF0YShkYXRhLCBjb25maWcsIHNlbGYpIHtcbiAgICBjb25zdCBsaXN0ID0gc2VsZi5ob29rLmxpc3Q7XG4gICAgaWYgKGNvbmZpZy5sb2FkaW5nVGVtcGxhdGUgJiYgbGlzdC5kYXRhID09PSB1bmRlZmluZWQgfHxcbiAgICAgIGxpc3QuZGF0YS5sZW5ndGggPT09IDApIHtcbiAgICAgIGNvbnN0IGRhdGFMb2FkaW5nVGVtcGxhdGUgPSBsaXN0Lmxpc3QucXVlcnlTZWxlY3RvcignW2RhdGEtbG9hZGluZy10ZW1wbGF0ZV0nKTtcbiAgICAgIGlmIChkYXRhTG9hZGluZ1RlbXBsYXRlKSB7XG4gICAgICAgIGRhdGFMb2FkaW5nVGVtcGxhdGUub3V0ZXJIVE1MID0gc2VsZi5saXN0VGVtcGxhdGU7XG4gICAgICB9XG4gICAgfVxuICAgIGlmICghc2VsZi5kZXN0cm95ZWQpIHtcbiAgICAgIHZhciBob29rTGlzdENoaWxkcmVuID0gbGlzdC5saXN0LmNoaWxkcmVuO1xuICAgICAgdmFyIG9ubHlEeW5hbWljTGlzdCA9IGhvb2tMaXN0Q2hpbGRyZW4ubGVuZ3RoID09PSAxICYmIGhvb2tMaXN0Q2hpbGRyZW5bMF0uaGFzQXR0cmlidXRlKCdkYXRhLWR5bmFtaWMnKTtcbiAgICAgIGlmIChvbmx5RHluYW1pY0xpc3QgJiYgZGF0YS5sZW5ndGggPT09IDApIHtcbiAgICAgICAgbGlzdC5oaWRlKCk7XG4gICAgICB9XG4gICAgICBsaXN0LnNldERhdGEuY2FsbChsaXN0LCBkYXRhKTtcbiAgICB9XG4gICAgc2VsZi5ub3RMb2FkaW5nKCk7XG4gICAgbGlzdC5jdXJyZW50SW5kZXggPSAwO1xuICB9LFxuXG4gIGJ1aWxkUGFyYW1zOiBmdW5jdGlvbihwYXJhbXMpIHtcbiAgICBpZiAoIXBhcmFtcykgcmV0dXJuICcnO1xuICAgIHZhciBwYXJhbXNBcnJheSA9IE9iamVjdC5rZXlzKHBhcmFtcykubWFwKGZ1bmN0aW9uKHBhcmFtKSB7XG4gICAgICByZXR1cm4gcGFyYW0gKyAnPScgKyAocGFyYW1zW3BhcmFtXSB8fCAnJyk7XG4gICAgfSk7XG4gICAgcmV0dXJuICc/JyArIHBhcmFtc0FycmF5LmpvaW4oJyYnKTtcbiAgfSxcblxuICBkZXN0cm95OiBmdW5jdGlvbiBkZXN0cm95KCkge1xuICAgIGlmICh0aGlzLnRpbWVvdXQpIHtcbiAgICAgIGNsZWFyVGltZW91dCh0aGlzLnRpbWVvdXQpO1xuICAgIH1cblxuICAgIHRoaXMuZGVzdHJveWVkID0gdHJ1ZTtcbiAgICB0aGlzLmhvb2sudHJpZ2dlci5yZW1vdmVFdmVudExpc3RlbmVyKCdrZXlkb3duLmRsJywgdGhpcy5ldmVudFdyYXBwZXIuZGVib3VuY2VUcmlnZ2VyKTtcbiAgICB0aGlzLmhvb2sudHJpZ2dlci5yZW1vdmVFdmVudExpc3RlbmVyKCdmb2N1cycsIHRoaXMuZXZlbnRXcmFwcGVyLmRlYm91bmNlVHJpZ2dlcik7XG4gIH1cbn07XG5cbmV4cG9ydCBkZWZhdWx0IGRyb3BsYWJBamF4RmlsdGVyO1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL3BsdWdpbnMvYWpheF9maWx0ZXIvYWpheF9maWx0ZXIuanMiXSwic291cmNlUm9vdCI6IiJ9