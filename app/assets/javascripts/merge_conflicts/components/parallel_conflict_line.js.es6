((global) => {

  global.mergeConflicts = global.mergeConflicts || {};

  global.mergeConflicts.parallelConflictLine = Vue.extend({
    props: {
      file: Object,
      line: Object
    },
    mixins: [global.mergeConflicts.utils, global.mergeConflicts.actions],
    template: '#parallel-conflict-line'
  });

})(window.gl || (window.gl = {}));
