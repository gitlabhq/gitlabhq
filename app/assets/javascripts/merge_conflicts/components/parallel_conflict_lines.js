/* eslint-disable no-param-reassign, comma-dangle */
import Vue from 'vue';

((global) => {
  global.mergeConflicts = global.mergeConflicts || {};

  global.mergeConflicts.parallelConflictLines = Vue.extend({
    mixins: [global.mergeConflicts.utils, global.mergeConflicts.actions],
    props: {
      file: {
        type: Object,
        required: true,
      },
    },
    template: `
      <table>
        <tr class="line_holder parallel" v-for="section in file.parallelLines">
          <template v-for="line in section">
            <td class="diff-line-num header" :class="lineCssClass(line)" v-if="line.isHeader"></td>
            <td class="line_content header" :class="lineCssClass(line)" v-if="line.isHeader">
              <strong>{{line.richText}}</strong>
              <button class="btn" @click="handleSelected(file, line.id, line.section)">{{line.buttonTitle}}</button>
            </td>
            <td class="diff-line-num old_line" :class="lineCssClass(line)" v-if="!line.isHeader">{{line.lineNumber}}</td>
            <td class="line_content parallel" :class="lineCssClass(line)" v-if="!line.isHeader" v-html="line.richText"></td>
          </template>
        </tr>
      </table>
    `,
  });
})(window.gl || (window.gl = {}));
