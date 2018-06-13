/* eslint-disable no-param-reassign */

import Vue from 'vue';
import actionsMixin from '../mixins/line_conflict_actions';
import utilsMixin from '../mixins/line_conflict_utils';

(global => {
  global.mergeConflicts = global.mergeConflicts || {};

  global.mergeConflicts.inlineConflictLines = Vue.extend({
    props: {
      file: Object,
    },
    mixins: [utilsMixin, actionsMixin],
  });
})(window.gl || (window.gl = {}));
