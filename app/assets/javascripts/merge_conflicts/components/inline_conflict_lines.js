/* eslint-disable no-param-reassign */

import Vue from 'vue';
import actionsMixin from '../mixins/line_conflict_actions';
import utilsMixin from '../mixins/line_conflict_utils';

(global => {
  global.mergeConflicts = global.mergeConflicts || {};

  global.mergeConflicts.inlineConflictLines = Vue.extend({
    mixins: [utilsMixin, actionsMixin],
    props: {
      file: {
        type: Object,
        required: true,
      },
    },
  });
})(window.gl || (window.gl = {}));
