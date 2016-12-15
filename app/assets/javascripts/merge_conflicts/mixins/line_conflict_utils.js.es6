/* eslint-disable no-param-reassign, quote-props, comma-dangle, padded-blocks */

((global) => {
  global.mergeConflicts = global.mergeConflicts || {};

  global.mergeConflicts.utils = {
    methods: {
      lineCssClass(line) {
        return {
          'head': line.isHead,
          'origin': line.isOrigin,
          'match': line.hasMatch,
          'selected': line.isSelected,
          'unselected': line.isUnselected
        };
      }
    }
  };

})(window.gl || (window.gl = {}));
