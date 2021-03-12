<script>
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import actionsMixin from '../mixins/line_conflict_actions';
import utilsMixin from '../mixins/line_conflict_utils';

export default {
  directives: {
    SafeHtml,
  },
  mixins: [utilsMixin, actionsMixin],
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <!-- Unfortunately there isn't a good key for these sections -->
  <!-- eslint-disable vue/require-v-for-key -->
  <table class="diff-wrap-lines code js-syntax-highlight">
    <tr v-for="section in file.parallelLines" class="line_holder parallel">
      <template v-for="line in section">
        <template v-if="line.isHeader">
          <td class="diff-line-num header" :class="lineCssClass(line)"></td>
          <td class="line_content header" :class="lineCssClass(line)">
            <strong>{{ line.richText }}</strong>
            <button class="btn" @click="handleSelected(file, line.id, line.section)">
              {{ line.buttonTitle }}
            </button>
          </td>
        </template>
        <template v-else>
          <td class="diff-line-num old_line" :class="lineCssClass(line)">
            {{ line.lineNumber }}
          </td>
          <td
            v-safe-html="line.richText"
            class="line_content parallel"
            :class="lineCssClass(line)"
          ></td>
        </template>
      </template>
    </tr>
  </table>
</template>
