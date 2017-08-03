/* eslint-disable */

import AjaxCache from '~/lib/utils/ajax_cache';

const Ajax = {
  _loadData: function _loadData(data, config, self) {
    if (config.loadingTemplate) {
      var dataLoadingTemplate = self.hook.list.list.querySelector('[data-loading-template]');
      if (dataLoadingTemplate) dataLoadingTemplate.outerHTML = self.listTemplate;
    }

    if (!self.destroyed) self.hook.list[config.method].call(self.hook.list, data);
  },
  preprocessing: function preprocessing(config, data) {
    let results = data;

    if (config.preprocessing && !data.preprocessed) {
      results = config.preprocessing(data);
      AjaxCache.override(config.endpoint, results);
    }

    return results;
  },
  init: function init(hook) {
    var self = this;
    self.destroyed = false;
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

    return AjaxCache.retrieve(config.endpoint)
      .then(self.preprocessing.bind(null, config))
      .then((data) => self._loadData(data, config, self))
      .catch(config.onError);
  },
  destroy: function() {
    this.destroyed = true;
  }
};

export default Ajax;
