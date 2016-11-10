/* eslint-disable */
((global) => {

  global.mergeConflicts = global.mergeConflicts || {};

  global.mergeConflicts.parallelConflictLines = Vue.extend({
    props: {
      file: Object
    },
    mixins: [global.mergeConflicts.utils],
    components: {
      'parallel-conflict-line': gl.mergeConflicts.parallelConflictLine
    }
  });

})(window.gl || (window.gl = {}));
