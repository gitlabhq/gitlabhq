// This is a true violation of @gitlab/no-runtime-template-compiler, as it relies on
// app/views/projects/merge_requests/conflicts/components/_inline_conflict_lines.html.haml
// for its template.
/* eslint-disable no-param-reassign, @gitlab/no-runtime-template-compiler */

import Vue from 'vue';
import actionsMixin from '../mixins/line_conflict_actions';
import utilsMixin from '../mixins/line_conflict_utils';

((global) => {
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
