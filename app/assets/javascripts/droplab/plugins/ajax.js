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
/******/ 	return __webpack_require__(__webpack_require__.s = 10);
/******/ })
/************************************************************************/
/******/ ({

/***/ 10:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
function droplabAjaxException(message) {
  this.message = message;
}

var droplabAjax = {
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
    if (config.loadingTemplate) {
      var dataLoadingTemplate = self.hook.list.list.querySelector('[data-loading-template]');
      if (dataLoadingTemplate) dataLoadingTemplate.outerHTML = self.listTemplate;
    }

    if (!self.destroyed) self.hook.list[config.method].call(self.hook.list, data);
  },
  init: function init(hook) {
    var self = this;
    self.destroyed = false;
    self.cache = self.cache || {};
    var config = hook.config.droplabAjax;
    this.hook = hook;
    if (!config || !config.endpoint || !config.method) {
      return;
    }
    if (config.method !== 'setData' && config.method !== 'addData') {
      return;
    }
    if (config.loadingTemplate) {
      var dynamicList = hook.list.list.querySelector('[data-dynamic]');
      var loadingTemplate = document.createElement('div');
      loadingTemplate.innerHTML = config.loadingTemplate;
      loadingTemplate.setAttribute('data-loading-template', '');
      this.listTemplate = dynamicList.outerHTML;
      dynamicList.outerHTML = loadingTemplate.outerHTML;
    }
    if (self.cache[config.endpoint]) {
      self._loadData(self.cache[config.endpoint], config, self);
    } else {
      this._loadUrlData(config.endpoint).then(function (d) {
        self._loadData(d, config, self);
      }).catch(function (e) {
        throw new droplabAjaxException(e.message || e);
      });
    }
  },
  destroy: function destroy() {
    this.destroyed = true;

    var dynamicList = this.hook.list.list.querySelector('[data-dynamic]');
    if (this.listTemplate && dynamicList) {
      dynamicList.outerHTML = this.listTemplate;
    }
  }
};

window.droplabAjax = droplabAjax;

exports.default = droplabAjax;

/***/ })

/******/ });
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAgZjM3NjcyYjdmNTI4YjQ3MmE0NGM/ZWM1ZioqKiIsIndlYnBhY2s6Ly8vLi9zcmMvcGx1Z2lucy9hamF4LmpzIl0sIm5hbWVzIjpbImRyb3BsYWJBamF4RXhjZXB0aW9uIiwibWVzc2FnZSIsImRyb3BsYWJBamF4IiwiX2xvYWRVcmxEYXRhIiwidXJsIiwic2VsZiIsIlByb21pc2UiLCJyZXNvbHZlIiwicmVqZWN0IiwieGhyIiwiWE1MSHR0cFJlcXVlc3QiLCJvcGVuIiwib25yZWFkeXN0YXRlY2hhbmdlIiwicmVhZHlTdGF0ZSIsIkRPTkUiLCJzdGF0dXMiLCJkYXRhIiwiSlNPTiIsInBhcnNlIiwicmVzcG9uc2VUZXh0IiwiY2FjaGUiLCJzZW5kIiwiX2xvYWREYXRhIiwiY29uZmlnIiwibG9hZGluZ1RlbXBsYXRlIiwiZGF0YUxvYWRpbmdUZW1wbGF0ZSIsImhvb2siLCJsaXN0IiwicXVlcnlTZWxlY3RvciIsIm91dGVySFRNTCIsImxpc3RUZW1wbGF0ZSIsImRlc3Ryb3llZCIsIm1ldGhvZCIsImNhbGwiLCJpbml0IiwiZW5kcG9pbnQiLCJkeW5hbWljTGlzdCIsImRvY3VtZW50IiwiY3JlYXRlRWxlbWVudCIsImlubmVySFRNTCIsInNldEF0dHJpYnV0ZSIsInRoZW4iLCJkIiwiY2F0Y2giLCJlIiwiZGVzdHJveSIsIndpbmRvdyJdLCJtYXBwaW5ncyI6IjtBQUFBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7OztBQUdBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBLG1EQUEyQyxjQUFjOztBQUV6RDtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLGFBQUs7QUFDTDtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBLG1DQUEyQiwwQkFBMEIsRUFB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QUFvQk0sWUFBWVAsU0FBaEM7QUFDQU8sa0JBQVlQLFNBQVosR0FBd0JMLGdCQUFnQkssU0FBeEM7QUFDRDtBQUNELFFBQUl4QixLQUFLZSxLQUFMLENBQVdHLE9BQU9ZLFFBQWxCLENBQUosRUFBaUM7QUFDL0I5QixXQUFLaUIsU0FBTCxDQUFlakIsS0FBS2UsS0FBTCxDQUFXRyxPQUFPWSxRQUFsQixDQUFmLEVBQTRDWixNQUE1QyxFQUFvRGxCLElBQXBEO0FBQ0QsS0FGRCxNQUVPO0FBQ0wsV0FBS0YsWUFBTCxDQUFrQm9CLE9BQU9ZLFFBQXpCLEVBQ0dNLElBREgsQ0FDUSxVQUFTQyxDQUFULEVBQVk7QUFDaEJyQyxhQUFLaUIsU0FBTCxDQUFlb0IsQ0FBZixFQUFrQm5CLE1BQWxCLEVBQTBCbEIsSUFBMUI7QUFDRCxPQUhILEVBR0tzQyxLQUhMLENBR1csVUFBU0MsQ0FBVCxFQUFZO0FBQ25CLGNBQU0sSUFBSTVDLG9CQUFKLENBQXlCNEMsRUFBRTNDLE9BQUYsSUFBYTJDLENBQXRDLENBQU47QUFDRCxPQUxIO0FBTUQ7QUFDRixHQTFEaUI7QUEyRGxCQyxXQUFTLG1CQUFXO0FBQ2xCLFNBQUtkLFNBQUwsR0FBaUIsSUFBakI7O0FBRUEsUUFBSUssY0FBYyxLQUFLVixJQUFMLENBQVVDLElBQVYsQ0FBZUEsSUFBZixDQUFvQkMsYUFBcEIsQ0FBa0MsZ0JBQWxDLENBQWxCO0FBQ0EsUUFBSSxLQUFLRSxZQUFMLElBQXFCTSxXQUF6QixFQUFzQztBQUNwQ0Esa0JBQVlQLFNBQVosR0FBd0IsS0FBS0MsWUFBN0I7QUFDRDtBQUNGO0FBbEVpQixDQUFwQjs7QUFxRUFnQixPQUFPNUMsV0FBUCxHQUFxQkEsV0FBckI7O2tCQUVlQSxXIiwiZmlsZSI6Ii4vZGlzdC9wbHVnaW5zL2FqYXguanMiLCJzb3VyY2VzQ29udGVudCI6WyIgXHQvLyBUaGUgbW9kdWxlIGNhY2hlXG4gXHR2YXIgaW5zdGFsbGVkTW9kdWxlcyA9IHt9O1xuXG4gXHQvLyBUaGUgcmVxdWlyZSBmdW5jdGlvblxuIFx0ZnVuY3Rpb24gX193ZWJwYWNrX3JlcXVpcmVfXyhtb2R1bGVJZCkge1xuXG4gXHRcdC8vIENoZWNrIGlmIG1vZHVsZSBpcyBpbiBjYWNoZVxuIFx0XHRpZihpbnN0YWxsZWRNb2R1bGVzW21vZHVsZUlkXSlcbiBcdFx0XHRyZXR1cm4gaW5zdGFsbGVkTW9kdWxlc1ttb2R1bGVJZF0uZXhwb3J0cztcblxuIFx0XHQvLyBDcmVhdGUgYSBuZXcgbW9kdWxlIChhbmQgcHV0IGl0IGludG8gdGhlIGNhY2hlKVxuIFx0XHR2YXIgbW9kdWxlID0gaW5zdGFsbGVkTW9kdWxlc1ttb2R1bGVJZF0gPSB7XG4gXHRcdFx0aTogbW9kdWxlSWQsXG4gXHRcdFx0bDogZmFsc2UsXG4gXHRcdFx0ZXhwb3J0czoge31cbiBcdFx0fTtcblxuIFx0XHQvLyBFeGVjdXRlIHRoZSBtb2R1bGUgZnVuY3Rpb25cbiBcdFx0bW9kdWxlc1ttb2R1bGVJZF0uY2FsbChtb2R1bGUuZXhwb3J0cywgbW9kdWxlLCBtb2R1bGUuZXhwb3J0cywgX193ZWJwYWNrX3JlcXVpcmVfXyk7XG5cbiBcdFx0Ly8gRmxhZyB0aGUgbW9kdWxlIGFzIGxvYWRlZFxuIFx0XHRtb2R1bGUubCA9IHRydWU7XG5cbiBcdFx0Ly8gUmV0dXJuIHRoZSBleHBvcnRzIG9mIHRoZSBtb2R1bGVcbiBcdFx0cmV0dXJuIG1vZHVsZS5leHBvcnRzO1xuIFx0fVxuXG5cbiBcdC8vIGV4cG9zZSB0aGUgbW9kdWxlcyBvYmplY3QgKF9fd2VicGFja19tb2R1bGVzX18pXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm0gPSBtb2R1bGVzO1xuXG4gXHQvLyBleHBvc2UgdGhlIG1vZHVsZSBjYWNoZVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5jID0gaW5zdGFsbGVkTW9kdWxlcztcblxuIFx0Ly8gaWRlbnRpdHkgZnVuY3Rpb24gZm9yIGNhbGxpbmcgaGFybW9ueSBpbXBvcnRzIHdpdGggdGhlIGNvcnJlY3QgY29udGV4dFxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5pID0gZnVuY3Rpb24odmFsdWUpIHsgcmV0dXJuIHZhbHVlOyB9O1xuXG4gXHQvLyBkZWZpbmUgZ2V0dGVyIGZ1bmN0aW9uIGZvciBoYXJtb255IGV4cG9ydHNcbiBcdF9fd2VicGFja19yZXF1aXJlX18uZCA9IGZ1bmN0aW9uKGV4cG9ydHMsIG5hbWUsIGdldHRlcikge1xuIFx0XHRpZighX193ZWJwYWNrX3JlcXVpcmVfXy5vKGV4cG9ydHMsIG5hbWUpKSB7XG4gXHRcdFx0T2JqZWN0LmRlZmluZVByb3BlcnR5KGV4cG9ydHMsIG5hbWUsIHtcbiBcdFx0XHRcdGNvbmZpZ3VyYWJsZTogZmFsc2UsXG4gXHRcdFx0XHRlbnVtZXJhYmxlOiB0cnVlLFxuIFx0XHRcdFx0Z2V0OiBnZXR0ZXJcbiBcdFx0XHR9KTtcbiBcdFx0fVxuIFx0fTtcblxuIFx0Ly8gZ2V0RGVmYXVsdEV4cG9ydCBmdW5jdGlvbiBmb3IgY29tcGF0aWJpbGl0eSB3aXRoIG5vbi1oYXJtb255IG1vZHVsZXNcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubiA9IGZ1bmN0aW9uKG1vZHVsZSkge1xuIFx0XHR2YXIgZ2V0dGVyID0gbW9kdWxlICYmIG1vZHVsZS5fX2VzTW9kdWxlID9cbiBcdFx0XHRmdW5jdGlvbiBnZXREZWZhdWx0KCkgeyByZXR1cm4gbW9kdWxlWydkZWZhdWx0J107IH0gOlxuIFx0XHRcdGZ1bmN0aW9uIGdldE1vZHVsZUV4cG9ydHMoKSB7IHJldHVybiBtb2R1bGU7IH07XG4gXHRcdF9fd2VicGFja19yZXF1aXJlX18uZChnZXR0ZXIsICdhJywgZ2V0dGVyKTtcbiBcdFx0cmV0dXJuIGdldHRlcjtcbiBcdH07XG5cbiBcdC8vIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbFxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5vID0gZnVuY3Rpb24ob2JqZWN0LCBwcm9wZXJ0eSkgeyByZXR1cm4gT2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsKG9iamVjdCwgcHJvcGVydHkpOyB9O1xuXG4gXHQvLyBfX3dlYnBhY2tfcHVibGljX3BhdGhfX1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5wID0gXCJcIjtcblxuIFx0Ly8gTG9hZCBlbnRyeSBtb2R1bGUgYW5kIHJldHVybiBleHBvcnRzXG4gXHRyZXR1cm4gX193ZWJwYWNrX3JlcXVpcmVfXyhfX3dlYnBhY2tfcmVxdWlyZV9fLnMgPSAxMCk7XG5cblxuXG4vLyBXRUJQQUNLIEZPT1RFUiAvL1xuLy8gd2VicGFjay9ib290c3RyYXAgZjM3NjcyYjdmNTI4YjQ3MmE0NGMiLCJmdW5jdGlvbiBkcm9wbGFiQWpheEV4Y2VwdGlvbihtZXNzYWdlKSB7XG4gIHRoaXMubWVzc2FnZSA9IG1lc3NhZ2U7XG59XG5cbmNvbnN0IGRyb3BsYWJBamF4ID0ge1xuICBfbG9hZFVybERhdGE6IGZ1bmN0aW9uIF9sb2FkVXJsRGF0YSh1cmwpIHtcbiAgICB2YXIgc2VsZiA9IHRoaXM7XG4gICAgcmV0dXJuIG5ldyBQcm9taXNlKGZ1bmN0aW9uKHJlc29sdmUsIHJlamVjdCkge1xuICAgICAgdmFyIHhociA9IG5ldyBYTUxIdHRwUmVxdWVzdDtcbiAgICAgIHhoci5vcGVuKCdHRVQnLCB1cmwsIHRydWUpO1xuICAgICAgeGhyLm9ucmVhZHlzdGF0ZWNoYW5nZSA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgaWYoeGhyLnJlYWR5U3RhdGUgPT09IFhNTEh0dHBSZXF1ZXN0LkRPTkUpIHtcbiAgICAgICAgICBpZiAoeGhyLnN0YXR1cyA9PT0gMjAwKSB7XG4gICAgICAgICAgICB2YXIgZGF0YSA9IEpTT04ucGFyc2UoeGhyLnJlc3BvbnNlVGV4dCk7XG4gICAgICAgICAgICBzZWxmLmNhY2hlW3VybF0gPSBkYXRhO1xuICAgICAgICAgICAgcmV0dXJuIHJlc29sdmUoZGF0YSk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHJldHVybiByZWplY3QoW3hoci5yZXNwb25zZVRleHQsIHhoci5zdGF0dXNdKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH07XG4gICAgICB4aHIuc2VuZCgpO1xuICAgIH0pO1xuICB9LFxuICBfbG9hZERhdGE6IGZ1bmN0aW9uIF9sb2FkRGF0YShkYXRhLCBjb25maWcsIHNlbGYpIHtcbiAgICBpZiAoY29uZmlnLmxvYWRpbmdUZW1wbGF0ZSkge1xuICAgICAgdmFyIGRhdGFMb2FkaW5nVGVtcGxhdGUgPSBzZWxmLmhvb2subGlzdC5saXN0LnF1ZXJ5U2VsZWN0b3IoJ1tkYXRhLWxvYWRpbmctdGVtcGxhdGVdJyk7XG4gICAgICBpZiAoZGF0YUxvYWRpbmdUZW1wbGF0ZSkgZGF0YUxvYWRpbmdUZW1wbGF0ZS5vdXRlckhUTUwgPSBzZWxmLmxpc3RUZW1wbGF0ZTtcbiAgICB9XG5cbiAgICBpZiAoIXNlbGYuZGVzdHJveWVkKSBzZWxmLmhvb2subGlzdFtjb25maWcubWV0aG9kXS5jYWxsKHNlbGYuaG9vay5saXN0LCBkYXRhKTtcbiAgfSxcbiAgaW5pdDogZnVuY3Rpb24gaW5pdChob29rKSB7XG4gICAgdmFyIHNlbGYgPSB0aGlzO1xuICAgIHNlbGYuZGVzdHJveWVkID0gZmFsc2U7XG4gICAgc2VsZi5jYWNoZSA9IHNlbGYuY2FjaGUgfHwge307XG4gICAgdmFyIGNvbmZpZyA9IGhvb2suY29uZmlnLmRyb3BsYWJBamF4O1xuICAgIHRoaXMuaG9vayA9IGhvb2s7XG4gICAgaWYgKCFjb25maWcgfHwgIWNvbmZpZy5lbmRwb2ludCB8fCAhY29uZmlnLm1ldGhvZCkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBpZiAoY29uZmlnLm1ldGhvZCAhPT0gJ3NldERhdGEnICYmIGNvbmZpZy5tZXRob2QgIT09ICdhZGREYXRhJykge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBpZiAoY29uZmlnLmxvYWRpbmdUZW1wbGF0ZSkge1xuICAgICAgdmFyIGR5bmFtaWNMaXN0ID0gaG9vay5saXN0Lmxpc3QucXVlcnlTZWxlY3RvcignW2RhdGEtZHluYW1pY10nKTtcbiAgICAgIHZhciBsb2FkaW5nVGVtcGxhdGUgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCdkaXYnKTtcbiAgICAgIGxvYWRpbmdUZW1wbGF0ZS5pbm5lckhUTUwgPSBjb25maWcubG9hZGluZ1RlbXBsYXRlO1xuICAgICAgbG9hZGluZ1RlbXBsYXRlLnNldEF0dHJpYnV0ZSgnZGF0YS1sb2FkaW5nLXRlbXBsYXRlJywgJycpO1xuICAgICAgdGhpcy5saXN0VGVtcGxhdGUgPSBkeW5hbWljTGlzdC5vdXRlckhUTUw7XG4gICAgICBkeW5hbWljTGlzdC5vdXRlckhUTUwgPSBsb2FkaW5nVGVtcGxhdGUub3V0ZXJIVE1MO1xuICAgIH1cbiAgICBpZiAoc2VsZi5jYWNoZVtjb25maWcuZW5kcG9pbnRdKSB7XG4gICAgICBzZWxmLl9sb2FkRGF0YShzZWxmLmNhY2hlW2NvbmZpZy5lbmRwb2ludF0sIGNvbmZpZywgc2VsZik7XG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMuX2xvYWRVcmxEYXRhKGNvbmZpZy5lbmRwb2ludClcbiAgICAgICAgLnRoZW4oZnVuY3Rpb24oZCkge1xuICAgICAgICAgIHNlbGYuX2xvYWREYXRhKGQsIGNvbmZpZywgc2VsZik7XG4gICAgICAgIH0pLmNhdGNoKGZ1bmN0aW9uKGUpIHtcbiAgICAgICAgICB0aHJvdyBuZXcgZHJvcGxhYkFqYXhFeGNlcHRpb24oZS5tZXNzYWdlIHx8IGUpO1xuICAgICAgICB9KTtcbiAgICB9XG4gIH0sXG4gIGRlc3Ryb3k6IGZ1bmN0aW9uKCkge1xuICAgIHRoaXMuZGVzdHJveWVkID0gdHJ1ZTtcblxuICAgIHZhciBkeW5hbWljTGlzdCA9IHRoaXMuaG9vay5saXN0Lmxpc3QucXVlcnlTZWxlY3RvcignW2RhdGEtZHluYW1pY10nKTtcbiAgICBpZiAodGhpcy5saXN0VGVtcGxhdGUgJiYgZHluYW1pY0xpc3QpIHtcbiAgICAgIGR5bmFtaWNMaXN0Lm91dGVySFRNTCA9IHRoaXMubGlzdFRlbXBsYXRlO1xuICAgIH1cbiAgfVxufTtcblxud2luZG93LmRyb3BsYWJBamF4ID0gZHJvcGxhYkFqYXg7XG5cbmV4cG9ydCBkZWZhdWx0IGRyb3BsYWJBamF4O1xuXG5cblxuLy8gV0VCUEFDSyBGT09URVIgLy9cbi8vIC4vc3JjL3BsdWdpbnMvYWpheC5qcyJdLCJzb3VyY2VSb290IjoiIn0=