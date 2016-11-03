/* eslint-disable */
((global) => {

  global.mergeConflicts = global.mergeConflicts || {};

  global.mergeConflicts.parallelConflictLines = Vue.extend({
    props: {
      file: Object
    },
    mixins: [global.mergeConflicts.utils, global.mergeConflicts.actions]
  });

})(window.gl || (window.gl = {}));
