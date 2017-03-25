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
/******/ 	return __webpack_require__(__webpack_require__.s = 5);
/******/ })
/************************************************************************/
/******/ ({

/***/ 5:
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

exports.default = droplabAjax;

/***/ })

/******/ });
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAgOTMzZmY3ZDVlZDM5M2RjNjNiY2E/MGFiZioqKioqKioqIiwid2VicGFjazovLy8uL3NyYy9wbHVnaW5zL2FqYXgvYWpheC5qcz8yMTc4Il0sIm5hbWVzIjpbImRyb3BsYWJBamF4RXhjZXB0aW9uIiwibWVzc2FnZSIsImRyb3BsYWJBamF4IiwiX2xvYWRVcmxEYXRhIiwidXJsIiwic2VsZiIsIlByb21pc2UiLCJyZXNvbHZlIiwicmVqZWN0IiwieGhyIiwiWE1MSHR0cFJlcXVlc3QiLCJvcGVuIiwib25yZWFkeXN0YXRlY2hhbmdlIiwicmVhZHlTdGF0ZSIsIkRPTkUiLCJzdGF0dXMiLCJkYXRhIiwiSlNPTiIsInBhcnNlIiwicmVzcG9uc2VUZXh0IiwiY2FjaGUiLCJzZW5kIiwiX2xvYWREYXRhIiwiY29uZmlnIiwibG9hZGluZ1RlbXBsYXRlIiwiZGF0YUxvYWRpbmdUZW1wbGF0ZSIsImhvb2siLCJsaXN0IiwicXVlcnlTZWxlY3RvciIsIm91dGVySFRNTCIsImxpc3RUZW1wbGF0ZSIsImRlc3Ryb3llZCIsIm1ldGhvZCIsImNhbGwiLCJpbml0IiwiZW5kcG9pbnQiLCJkeW5hbWljTGlzdCIsImRvY3VtZW50IiwiY3JlYXRlRWxlbWVudCIsImlubmVySFRNTCIsInNldEF0dHJpYnV0ZSIsInRoZW4iLCJkIiwiY2F0Y2giLCJlIiwiZGVzdHJveSJdLCJtYXBwaW5ncyI6IjtBQUFBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7O0FBRUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQUVBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBO0FBQ0E7OztBQUdBO0FBQ0E7O0FBRUE7QUFDQTs7QUFFQTtBQUNBLG1EQUEyQyxjQUFjOztBQUV6RDtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLGFBQUs7QUFDTDtBQUNBOztBQUVBO0FBQ0E7QUFDQTtBQUNBLG1DQUEyQiwwQkFB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WUFBTCxHQUFvQk0sWUFBWVAsU0FBaEM7QUFDQU8sa0JBQVlQLFNBQVosR0FBd0JMLGdCQUFnQkssU0FBeEM7QUFDRDtBQUNELFFBQUl4QixLQUFLZSxLQUFMLENBQVdHLE9BQU9ZLFFBQWxCLENBQUosRUFBaUM7QUFDL0I5QixXQUFLaUIsU0FBTCxDQUFlakIsS0FBS2UsS0FBTCxDQUFXRyxPQUFPWSxRQUFsQixDQUFmLEVBQTRDWixNQUE1QyxFQUFvRGxCLElBQXBEO0FBQ0QsS0FGRCxNQUVPO0FBQ0wsV0FBS0YsWUFBTCxDQUFrQm9CLE9BQU9ZLFFBQXpCLEVBQ0dNLElBREgsQ0FDUSxVQUFTQyxDQUFULEVBQVk7QUFDaEJyQyxhQUFLaUIsU0FBTCxDQUFlb0IsQ0FBZixFQUFrQm5CLE1BQWxCLEVBQTBCbEIsSUFBMUI7QUFDRCxPQUhILEVBR0tzQyxLQUhMLENBR1csVUFBU0MsQ0FBVCxFQUFZO0FBQ25CLGNBQU0sSUFBSTVDLG9CQUFKLENBQXlCNEMsRUFBRTNDLE9BQUYsSUFBYTJDLENBQXRDLENBQU47QUFDRCxPQUxIO0FBTUQ7QUFDRixHQTFEaUI7QUEyRGxCQyxXQUFTLG1CQUFXO0FBQ2xCLFNBQUtkLFNBQUwsR0FBaUIsSUFBakI7O0FBRUEsUUFBSUssY0FBYyxLQUFLVixJQUFMLENBQVVDLElBQVYsQ0FBZUEsSUFBZixDQUFvQkMsYUFBcEIsQ0FBa0MsZ0JBQWxDLENBQWxCO0FBQ0EsUUFBSSxLQUFLRSxZQUFMLElBQXFCTSxXQUF6QixFQUFzQztBQUNwQ0Esa0JBQVlQLFNBQVosR0FBd0IsS0FBS0MsWUFBN0I7QUFDRDtBQUNGO0FBbEVpQixDQUFwQjs7a0JBcUVlNUIsVyIsImZpbGUiOiIuL2Rpc3QvcGx1Z2lucy9hamF4LmpzIiwic291cmNlc0NvbnRlbnQiOlsiIFx0Ly8gVGhlIG1vZHVsZSBjYWNoZVxuIFx0dmFyIGluc3RhbGxlZE1vZHVsZXMgPSB7fTtcblxuIFx0Ly8gVGhlIHJlcXVpcmUgZnVuY3Rpb25cbiBcdGZ1bmN0aW9uIF9fd2VicGFja19yZXF1aXJlX18obW9kdWxlSWQpIHtcblxuIFx0XHQvLyBDaGVjayBpZiBtb2R1bGUgaXMgaW4gY2FjaGVcbiBcdFx0aWYoaW5zdGFsbGVkTW9kdWxlc1ttb2R1bGVJZF0pXG4gXHRcdFx0cmV0dXJuIGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdLmV4cG9ydHM7XG5cbiBcdFx0Ly8gQ3JlYXRlIGEgbmV3IG1vZHVsZSAoYW5kIHB1dCBpdCBpbnRvIHRoZSBjYWNoZSlcbiBcdFx0dmFyIG1vZHVsZSA9IGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdID0ge1xuIFx0XHRcdGk6IG1vZHVsZUlkLFxuIFx0XHRcdGw6IGZhbHNlLFxuIFx0XHRcdGV4cG9ydHM6IHt9XG4gXHRcdH07XG5cbiBcdFx0Ly8gRXhlY3V0ZSB0aGUgbW9kdWxlIGZ1bmN0aW9uXG4gXHRcdG1vZHVsZXNbbW9kdWxlSWRdLmNhbGwobW9kdWxlLmV4cG9ydHMsIG1vZHVsZSwgbW9kdWxlLmV4cG9ydHMsIF9fd2VicGFja19yZXF1aXJlX18pO1xuXG4gXHRcdC8vIEZsYWcgdGhlIG1vZHVsZSBhcyBsb2FkZWRcbiBcdFx0bW9kdWxlLmwgPSB0cnVlO1xuXG4gXHRcdC8vIFJldHVybiB0aGUgZXhwb3J0cyBvZiB0aGUgbW9kdWxlXG4gXHRcdHJldHVybiBtb2R1bGUuZXhwb3J0cztcbiBcdH1cblxuXG4gXHQvLyBleHBvc2UgdGhlIG1vZHVsZXMgb2JqZWN0IChfX3dlYnBhY2tfbW9kdWxlc19fKVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5tID0gbW9kdWxlcztcblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGUgY2FjaGVcbiBcdF9fd2VicGFja19yZXF1aXJlX18uYyA9IGluc3RhbGxlZE1vZHVsZXM7XG5cbiBcdC8vIGlkZW50aXR5IGZ1bmN0aW9uIGZvciBjYWxsaW5nIGhhcm1vbnkgaW1wb3J0cyB3aXRoIHRoZSBjb3JyZWN0IGNvbnRleHRcbiBcdF9fd2VicGFja19yZXF1aXJlX18uaSA9IGZ1bmN0aW9uKHZhbHVlKSB7IHJldHVybiB2YWx1ZTsgfTtcblxuIFx0Ly8gZGVmaW5lIGdldHRlciBmdW5jdGlvbiBmb3IgaGFybW9ueSBleHBvcnRzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQgPSBmdW5jdGlvbihleHBvcnRzLCBuYW1lLCBnZXR0ZXIpIHtcbiBcdFx0aWYoIV9fd2VicGFja19yZXF1aXJlX18ubyhleHBvcnRzLCBuYW1lKSkge1xuIFx0XHRcdE9iamVjdC5kZWZpbmVQcm9wZXJ0eShleHBvcnRzLCBuYW1lLCB7XG4gXHRcdFx0XHRjb25maWd1cmFibGU6IGZhbHNlLFxuIFx0XHRcdFx0ZW51bWVyYWJsZTogdHJ1ZSxcbiBcdFx0XHRcdGdldDogZ2V0dGVyXG4gXHRcdFx0fSk7XG4gXHRcdH1cbiBcdH07XG5cbiBcdC8vIGdldERlZmF1bHRFeHBvcnQgZnVuY3Rpb24gZm9yIGNvbXBhdGliaWxpdHkgd2l0aCBub24taGFybW9ueSBtb2R1bGVzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm4gPSBmdW5jdGlvbihtb2R1bGUpIHtcbiBcdFx0dmFyIGdldHRlciA9IG1vZHVsZSAmJiBtb2R1bGUuX19lc01vZHVsZSA/XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0RGVmYXVsdCgpIHsgcmV0dXJuIG1vZHVsZVsnZGVmYXVsdCddOyB9IDpcbiBcdFx0XHRmdW5jdGlvbiBnZXRNb2R1bGVFeHBvcnRzKCkgeyByZXR1cm4gbW9kdWxlOyB9O1xuIFx0XHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQoZ2V0dGVyLCAnYScsIGdldHRlcik7XG4gXHRcdHJldHVybiBnZXR0ZXI7XG4gXHR9O1xuXG4gXHQvLyBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGxcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubyA9IGZ1bmN0aW9uKG9iamVjdCwgcHJvcGVydHkpIHsgcmV0dXJuIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbChvYmplY3QsIHByb3BlcnR5KTsgfTtcblxuIFx0Ly8gX193ZWJwYWNrX3B1YmxpY19wYXRoX19cbiBcdF9fd2VicGFja19yZXF1aXJlX18ucCA9IFwiXCI7XG5cbiBcdC8vIExvYWQgZW50cnkgbW9kdWxlIGFuZCByZXR1cm4gZXhwb3J0c1xuIFx0cmV0dXJuIF9fd2VicGFja19yZXF1aXJlX18oX193ZWJwYWNrX3JlcXVpcmVfXy5zID0gNSk7XG5cblxuXG4vLyBXRUJQQUNLIEZPT1RFUiAvL1xuLy8gd2VicGFjay9ib290c3RyYXAgOTMzZmY3ZDVlZDM5M2RjNjNiY2EiLCJmdW5jdGlvbiBkcm9wbGFiQWpheEV4Y2VwdGlvbihtZXNzYWdlKSB7XG4gIHRoaXMubWVzc2FnZSA9IG1lc3NhZ2U7XG59XG5cbmNvbnN0IGRyb3BsYWJBamF4ID0ge1xuICBfbG9hZFVybERhdGE6IGZ1bmN0aW9uIF9sb2FkVXJsRGF0YSh1cmwpIHtcbiAgICB2YXIgc2VsZiA9IHRoaXM7XG4gICAgcmV0dXJuIG5ldyBQcm9taXNlKGZ1bmN0aW9uKHJlc29sdmUsIHJlamVjdCkge1xuICAgICAgdmFyIHhociA9IG5ldyBYTUxIdHRwUmVxdWVzdDtcbiAgICAgIHhoci5vcGVuKCdHRVQnLCB1cmwsIHRydWUpO1xuICAgICAgeGhyLm9ucmVhZHlzdGF0ZWNoYW5nZSA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgaWYoeGhyLnJlYWR5U3RhdGUgPT09IFhNTEh0dHBSZXF1ZXN0LkRPTkUpIHtcbiAgICAgICAgICBpZiAoeGhyLnN0YXR1cyA9PT0gMjAwKSB7XG4gICAgICAgICAgICB2YXIgZGF0YSA9IEpTT04ucGFyc2UoeGhyLnJlc3BvbnNlVGV4dCk7XG4gICAgICAgICAgICBzZWxmLmNhY2hlW3VybF0gPSBkYXRhO1xuICAgICAgICAgICAgcmV0dXJuIHJlc29sdmUoZGF0YSk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHJldHVybiByZWplY3QoW3hoci5yZXNwb25zZVRleHQsIHhoci5zdGF0dXNdKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH07XG4gICAgICB4aHIuc2VuZCgpO1xuICAgIH0pO1xuICB9LFxuICBfbG9hZERhdGE6IGZ1bmN0aW9uIF9sb2FkRGF0YShkYXRhLCBjb25maWcsIHNlbGYpIHtcbiAgICBpZiAoY29uZmlnLmxvYWRpbmdUZW1wbGF0ZSkge1xuICAgICAgdmFyIGRhdGFMb2FkaW5nVGVtcGxhdGUgPSBzZWxmLmhvb2subGlzdC5saXN0LnF1ZXJ5U2VsZWN0b3IoJ1tkYXRhLWxvYWRpbmctdGVtcGxhdGVdJyk7XG4gICAgICBpZiAoZGF0YUxvYWRpbmdUZW1wbGF0ZSkgZGF0YUxvYWRpbmdUZW1wbGF0ZS5vdXRlckhUTUwgPSBzZWxmLmxpc3RUZW1wbGF0ZTtcbiAgICB9XG5cbiAgICBpZiAoIXNlbGYuZGVzdHJveWVkKSBzZWxmLmhvb2subGlzdFtjb25maWcubWV0aG9kXS5jYWxsKHNlbGYuaG9vay5saXN0LCBkYXRhKTtcbiAgfSxcbiAgaW5pdDogZnVuY3Rpb24gaW5pdChob29rKSB7XG4gICAgdmFyIHNlbGYgPSB0aGlzO1xuICAgIHNlbGYuZGVzdHJveWVkID0gZmFsc2U7XG4gICAgc2VsZi5jYWNoZSA9IHNlbGYuY2FjaGUgfHwge307XG4gICAgdmFyIGNvbmZpZyA9IGhvb2suY29uZmlnLmRyb3BsYWJBamF4O1xuICAgIHRoaXMuaG9vayA9IGhvb2s7XG4gICAgaWYgKCFjb25maWcgfHwgIWNvbmZpZy5lbmRwb2ludCB8fCAhY29uZmlnLm1ldGhvZCkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBpZiAoY29uZmlnLm1ldGhvZCAhPT0gJ3NldERhdGEnICYmIGNvbmZpZy5tZXRob2QgIT09ICdhZGREYXRhJykge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBpZiAoY29uZmlnLmxvYWRpbmdUZW1wbGF0ZSkge1xuICAgICAgdmFyIGR5bmFtaWNMaXN0ID0gaG9vay5saXN0Lmxpc3QucXVlcnlTZWxlY3RvcignW2RhdGEtZHluYW1pY10nKTtcbiAgICAgIHZhciBsb2FkaW5nVGVtcGxhdGUgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCdkaXYnKTtcbiAgICAgIGxvYWRpbmdUZW1wbGF0ZS5pbm5lckhUTUwgPSBjb25maWcubG9hZGluZ1RlbXBsYXRlO1xuICAgICAgbG9hZGluZ1RlbXBsYXRlLnNldEF0dHJpYnV0ZSgnZGF0YS1sb2FkaW5nLXRlbXBsYXRlJywgJycpO1xuICAgICAgdGhpcy5saXN0VGVtcGxhdGUgPSBkeW5hbWljTGlzdC5vdXRlckhUTUw7XG4gICAgICBkeW5hbWljTGlzdC5vdXRlckhUTUwgPSBsb2FkaW5nVGVtcGxhdGUub3V0ZXJIVE1MO1xuICAgIH1cbiAgICBpZiAoc2VsZi5jYWNoZVtjb25maWcuZW5kcG9pbnRdKSB7XG4gICAgICBzZWxmLl9sb2FkRGF0YShzZWxmLmNhY2hlW2NvbmZpZy5lbmRwb2ludF0sIGNvbmZpZywgc2VsZik7XG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMuX2xvYWRVcmxEYXRhKGNvbmZpZy5lbmRwb2ludClcbiAgICAgICAgLnRoZW4oZnVuY3Rpb24oZCkge1xuICAgICAgICAgIHNlbGYuX2xvYWREYXRhKGQsIGNvbmZpZywgc2VsZik7XG4gICAgICAgIH0pLmNhdGNoKGZ1bmN0aW9uKGUpIHtcbiAgICAgICAgICB0aHJvdyBuZXcgZHJvcGxhYkFqYXhFeGNlcHRpb24oZS5tZXNzYWdlIHx8IGUpO1xuICAgICAgICB9KTtcbiAgICB9XG4gIH0sXG4gIGRlc3Ryb3k6IGZ1bmN0aW9uKCkge1xuICAgIHRoaXMuZGVzdHJveWVkID0gdHJ1ZTtcblxuICAgIHZhciBkeW5hbWljTGlzdCA9IHRoaXMuaG9vay5saXN0Lmxpc3QucXVlcnlTZWxlY3RvcignW2RhdGEtZHluYW1pY10nKTtcbiAgICBpZiAodGhpcy5saXN0VGVtcGxhdGUgJiYgZHluYW1pY0xpc3QpIHtcbiAgICAgIGR5bmFtaWNMaXN0Lm91dGVySFRNTCA9IHRoaXMubGlzdFRlbXBsYXRlO1xuICAgIH1cbiAgfVxufTtcblxuZXhwb3J0IGRlZmF1bHQgZHJvcGxhYkFqYXg7XG5cblxuXG4vLyBXRUJQQUNLIEZPT1RFUiAvL1xuLy8gLi9zcmMvcGx1Z2lucy9hamF4L2FqYXguanMiXSwic291cmNlUm9vdCI6IiJ9