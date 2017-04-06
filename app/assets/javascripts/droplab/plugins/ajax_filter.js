/* eslint-disable */

const AjaxFilter = {
  init: function(hook) {
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
    var config = this.hook.config.AjaxFilter;
    var searchValue = this.trigger.value;
    if (!config || !config.endpoint || !config.searchKey) {
      return;
    }
    if (config.searchValueFunction) {
      searchValue = config.searchValueFunction();
    }
    if (config.loadingTemplate && this.hook.list.data === undefined ||
      this.hook.list.data.length === 0) {
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
      this._loadUrlData(url)
        .then(function(data) {
          self._loadData(data, config, self);
        }, config.onError).catch(config.onError);
    }
  },

  _loadUrlData: function _loadUrlData(url) {
    var self = this;
    return new Promise(function(resolve, reject) {
      var xhr = new XMLHttpRequest;
      xhr.open('GET', url, true);
      xhr.onreadystatechange = function () {
        if(xhr.readyState === XMLHttpRequest.DONE) {
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
    const list = self.hook.list;
    if (config.loadingTemplate && list.data === undefined ||
      list.data.length === 0) {
      const dataLoadingTemplate = list.list.querySelector('[data-loading-template]');
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

  buildParams: function(params) {
    if (!params) return '';
    var paramsArray = Object.keys(params).map(function(param) {
      return param + '=' + (params[param] || '');
    });
    return '?' + paramsArray.join('&');
  },

  destroy: function destroy() {
    if (this.timeout)clearTimeout(this.timeout);
    this.destroyed = true;

    this.hook.trigger.removeEventListener('keydown.dl', this.eventWrapper.debounceTrigger);
    this.hook.trigger.removeEventListener('focus', this.eventWrapper.debounceTrigger);
  }
};

export default AjaxFilter;
