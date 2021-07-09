<script>
/* eslint-disable vue/no-v-html */
import { GlTooltip, GlSprintf, GlIcon } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';

export default {
  components: {
    ClipboardButton,
    FileIcon,
    GlIcon,
    GlSprintf,
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
          <gl-icon :name="collapseIcon" :size="16" class="gl-mr-2" />
        </div>
        <file-icon :file-name="filePath" :size="16" aria-hidden="true" css-classes="gl-mr-2" />
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
          category="tertiary"
          size="small"
          css-class="gl-mr-1"
        />

        <gl-sprintf v-if="errorFn" :message="__('%{spanStart}in%{spanEnd} %{errorFn}')">
          <template #span="{ content }">
            <span class="gl-text-gray-200">{{ content }}&nbsp;</span>
          </template>
          <template #errorFn>
            <strong>{{ errorFn }}&nbsp;</strong>
          </template>
        </gl-sprintf>

        <gl-sprintf :message="__('%{spanStart}at line%{spanEnd} %{errorLine}%{errorColumn}')">
          <template #span="{ content }">
            <span class="gl-text-gray-200">{{ content }}&nbsp;</span>
          </template>
          <template #errorLine>
            <strong>{{ errorLine }}</strong>
          </template>
          <template #errorColumn>
            <strong v-if="errorColumn">:{{ errorColumn }}</strong>
          </template>
        </gl-sprintf>
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
