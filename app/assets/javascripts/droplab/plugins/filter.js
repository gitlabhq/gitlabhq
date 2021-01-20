/* eslint-disable */

const Filter = {
  keydown: function (e) {
    if (this.destroyed) return;

    var hiddenCount = 0;
    var dataHiddenCount = 0;

    var list = e.detail.hook.list;
    var data = list.data;
    var value = e.detail.hook.trigger.value.toLowerCase();
    var config = e.detail.hook.config.Filter;
    var matches = [];
    var filterFunction;
    // will only work on dynamically set data
    if (!data) {
      return;
    }

    if (config && config.filterFunction && typeof config.filterFunction === 'function') {
      filterFunction = config.filterFunction;
    } else {
      filterFunction = function (o) {
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
      list.setData(matches);
      list.currentIndex = 0;
    }
  },

  debounceKeydown: function debounceKeydown(e) {
    if (
      [
        13, // enter
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
        93, // select
      ].indexOf(e.detail.which || e.detail.keyCode) > -1
    )
      return;

    if (this.timeout) clearTimeout(this.timeout);
    this.timeout = setTimeout(this.keydown.bind(this, e), 200);
  },

  init: function init(hook) {
    var config = hook.config.Filter;

    if (!config || !config.template) return;

    this.hook = hook;
    this.destroyed = false;

    this.eventWrapper = {};
    this.eventWrapper.debounceKeydown = this.debounceKeydown.bind(this);

    this.hook.trigger.addEventListener('keydown.dl', this.eventWrapper.debounceKeydown);
    this.hook.trigger.addEventListener('mousedown.dl', this.eventWrapper.debounceKeydown);
  },

  destroy: function destroy() {
    if (this.timeout) clearTimeout(this.timeout);
    this.destroyed = true;

    this.hook.trigger.removeEventListener('keydown.dl', this.eventWrapper.debounceKeydown);
    this.hook.trigger.removeEventListener('mousedown.dl', this.eventWrapper.debounceKeydown);
  },
};

export default Filter;
