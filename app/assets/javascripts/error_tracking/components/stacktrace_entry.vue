<script>
import { escape } from 'lodash';
import { GlTooltip } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    ClipboardButton,
    FileIcon,
    Icon,
  },
  directives: {
    GlTooltip,
  },
  props: {
    lines: {
      type: Array,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
    errorFn: {
      type: String,
      required: false,
      default: '',
    },
    errorLine: {
      type: Number,
      required: false,
      default: 0,
    },
    errorColumn: {
      type: Number,
      required: false,
      default: 0,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isExpanded: this.expanded,
    };
  },
  computed: {
    hasCode() {
      return Boolean(this.lines.length);
    },
    collapseIcon() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
    errorFnText() {
      return this.errorFn
        ? sprintf(
            __(`%{spanStart}in%{spanEnd} %{errorFn}`),
            {
              errorFn: `<strong>${escape(this.errorFn)}</strong>`,
              spanStart: `<span class="text-tertiary">`,
              spanEnd: `</span>`,
            },
            false,
          )
        : '';
    },
    errorPositionText() {
      return this.errorLine
        ? sprintf(
            __(`%{spanStart}at line%{spanEnd} %{errorLine}%{errorColumn}`),
            {
              errorLine: `<strong>${this.errorLine}</strong>`,
              errorColumn: this.errorColumn ? `:<strong>${this.errorColumn}</strong>` : ``,
              spanStart: `<span class="text-tertiary">`,
              spanEnd: `</span>`,
            },
            false,
          )
        : '';
    },
    errorInfo() {
      return `${this.errorFnText} ${this.errorPositionText}`;
    },
  },
  methods: {
    isHighlighted(lineNum) {
      return lineNum === this.errorLine;
    },
    toggle() {
      this.isExpanded = !this.isExpanded;
    },
    lineNum(line) {
      return line[0];
    },
    lineCode(line) {
      return line[1];
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <div class="file-holder">
    <div ref="header" class="file-title file-title-flex-parent">
      <div class="file-header-content d-flex align-content-center">
        <div v-if="hasCode" class="d-inline-block cursor-pointer" @click="toggle()">
          <icon :name="collapseIcon" :size="16" aria-hidden="true" class="append-right-5" />
        </div>
        <file-icon
          :file-name="filePath"
          :size="18"
          aria-hidden="true"
          css-classes="append-right-5"
        />
        <strong
          v-gl-tooltip
          :title="filePath"
          class="file-title-name d-inline-block overflow-hidden text-truncate limited-width"
          data-container="body"
        >
          {{ filePath }}
        </strong>
        <clipboard-button
          :title="__('Copy file path')"
          :text="filePath"
          css-class="btn-default btn-transparent btn-clipboard position-static"
        />
        <span v-html="errorInfo"></span>
      </div>
    </div>

    <table v-if="isExpanded" :class="$options.userColorScheme" class="code js-syntax-highlight">
      <tbody>
        <template v-for="(line, index) in lines">
          <tr :key="`stacktrace-line-${index}`" class="line_holder">
            <td class="diff-line-num" :class="{ old: isHighlighted(lineNum(line)) }">
              {{ lineNum(line) }}
            </td>
            <td
              class="line_content"
              :class="{ old: isHighlighted(lineNum(line)) }"
              v-html="lineCode(line)"
            ></td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>
