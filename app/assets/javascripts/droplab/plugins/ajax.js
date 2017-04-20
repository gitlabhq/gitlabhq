/* eslint-disable */

const Ajax = {
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
    var config = hook.config.Ajax;
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
      this._loadUrlData(config.endpoint)
        .then(function(d) {
          self._loadData(d, config, self);
        }, config.onError).catch(config.onError);
    }
  },
  destroy: function() {
    this.destroyed = true;
  }
};

export default Ajax;
