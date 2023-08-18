<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import syntaxHighlight from '~/syntax_highlight';
import { SYNTAX_HIGHLIGHT_CLASS } from '../constants';
import utilsMixin from '../mixins/line_conflict_utils';

export default {
  directives: {
    SafeHtml,
  },
  mixins: [utilsMixin],
  SYNTAX_HIGHLIGHT_CLASS,
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  mounted() {
    syntaxHighlight(document.querySelectorAll(`.${SYNTAX_HIGHLIGHT_CLASS}`));
  },
  methods: {
    ...mapActions(['handleSelected']),
  },
};
</script>
<template>
  <!-- Unfortunately there isn't a good key for these sections -->
  <!-- eslint-disable vue/require-v-for-key -->
  <table :class="['diff-wrap-lines code', $options.SYNTAX_HIGHLIGHT_CLASS]">
    <tr v-for="section in file.parallelLines" class="line_holder parallel">
      <template v-for="line in section">
        <template v-if="line.isHeader">
          <td class="diff-line-num header" :class="lineCssClass(line)"></td>
          <td class="line_content header" :class="lineCssClass(line)">
            <strong>{{ line.richText }}</strong>
            <button
              type="button"
              class="gl-border-1 gl-border-solid"
              @click="handleSelected({ file, line })"
            >
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
