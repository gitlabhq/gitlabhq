/* eslint-disable padded-blocks, no-param-reassign, comma-dangle */
/* global Vue */

((global) => {

  global.mergeConflicts = global.mergeConflicts || {};

  global.mergeConflicts.inlineConflictLines = Vue.extend({
    props: {
      file: Object
    },
    mixins: [global.mergeConflicts.utils, global.mergeConflicts.actions],
  });

})(window.gl || (window.gl = {}));
