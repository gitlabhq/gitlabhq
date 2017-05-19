<script>
import successIcon from 'icons/_icon_status_success.svg';
import errorIcon from 'icons/_icon_status_failed.svg';
import issuesBlock from './mr_widget_code_quality_issues.vue';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';
import '../../lib/utils/text_utility';

export default {
  name: 'MRWidgetCodeQuality',

  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    loadingFailed: {
      type: Boolean,
      required: true,
    },
    newIssues: {
      type: Array,
      required: false,
      default: () => ([]),
    },
    resolvedIssues: {
      type: Array,
      required: false,
      default: () => ([]),
    },
  },

  components: {
    issuesBlock,
    loadingIcon,
  },

  data() {
    return {
      successIcon,
      errorIcon,
      collapseText: 'Expand',
      isCollapsed: true,
    };
  },

  computed: {
    stateIcon() {
      return this.newIssues.length ? errorIcon : successIcon;
    },

    codeText() {
      let newIssuesText = '';
      let resolvedIssuesText = '';

      if (this.newIssues.length) {
        newIssuesText = `degraded on ${this.newIssues.length} ${this.pointsText(this.newIssues)}`;
      }

      if (this.resolvedIssues.length) {
        resolvedIssuesText = `improved on ${this.resolvedIssues.length} ${this.pointsText(this.resolvedIssues)}`;
      }

      const connector = this.resolvedIssues.length && this.newIssues.length ? 'and' : '';

      return `Code quality ${resolvedIssuesText} ${connector} ${newIssuesText}`;
    },
  },

  methods: {
    pointsText(issues) {
      return gl.text.pluralize('point', issues.length);
    },

    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;

      const text = this.isCollapsed ? 'Expand' : 'Collapse';
      this.collapseText = text;
    },
  },
};
</script>
<template>
  <section class="mr-widget-code-quality">
    <div
      v-if="isLoading"
      class="padding-left">
      <i
        class="fa fa-spinner fa-spin"
        aria-hidden="true">
      </i>
      Loading codeclimate report.
    </div>

    <div v-else-if="!isLoading && !loadingFailed">
      <span
        class="padding-left ci-status-icon"
        :class="{
          'ci-status-icon-failed': newIssues.length,
          'ci-status-icon-passed': newIssues.length === 0
        }"
        v-html="stateIcon">
      </span>
      <span>
        {{codeText}}
      </span>

      <button
        type="button"
        class="btn-link btn-blank"
        @click="toggleCollapsed">
        {{collapseText}}
      </button>

      <div
        class="code-quality-container"
        v-show="!isCollapsed">
        <issues-block
          class="js-mr-code-new-issues"
          v-if="newIssues.length"
          type="failed"
          :issues="newIssues"
          />

        <issues-block
          class="js-mr-code-resolved-issues"
          v-if="resolvedIssues.length"
          type="success"
          :issues="resolvedIssues"
          />
      </div>
    </div>
    <div
      v-else-if="loadingFailed"
      class="padding-left">
      Failed to load codeclimate report.
    </div>
  </section>
</template>
