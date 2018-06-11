/* eslint-disable no-param-reassign, comma-dangle */

import Vue from 'vue';

((global) => {
  global.mergeConflicts = global.mergeConflicts || {};

  global.mergeConflicts.inlineConflictLines = Vue.extend({
    mixins: [global.mergeConflicts.utils, global.mergeConflicts.actions],
    props: {
      file: Object
    },
  });
})(window.gl || (window.gl = {}));
