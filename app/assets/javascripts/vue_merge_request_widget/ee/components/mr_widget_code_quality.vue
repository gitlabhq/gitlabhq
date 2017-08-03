<script>
import successIcon from 'icons/_icon_status_success.svg';
import errorIcon from 'icons/_icon_status_failed.svg';
import issuesBlock from './mr_widget_code_quality_issues.vue';
import loadingIcon from '../../../vue_shared/components/loading_icon.vue';
import '../../../lib/utils/text_utility';

export default {
  name: 'MRWidgetCodeQuality',

  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },

  components: {
    issuesBlock,
    loadingIcon,
  },

  data() {
    return {
      collapseText: 'Expand',
      isCollapsed: true,
      isLoading: false,
      loadingFailed: false,
    };
  },

  computed: {
    stateIcon() {
      return this.mr.codeclimateMetrics.newIssues.length ? errorIcon : successIcon;
    },

    hasNoneIssues() {
      const { newIssues, resolvedIssues } = this.mr.codeclimateMetrics;
      return !newIssues.length && !resolvedIssues.length;
    },

    hasIssues() {
      const { newIssues, resolvedIssues } = this.mr.codeclimateMetrics;
      return newIssues.length || resolvedIssues.length;
    },

    codeText() {
      const { newIssues, resolvedIssues } = this.mr.codeclimateMetrics;
      let newIssuesText;
      let resolvedIssuesText;
      let text = [];

      if (this.hasNoneIssues) {
        text.push('No changes to code quality.');
      } else if (this.hasIssues) {
        if (newIssues.length) {
          newIssuesText = ` degraded on ${newIssues.length} ${this.pointsText(newIssues)}`;
        }

        if (resolvedIssues.length) {
          resolvedIssuesText = ` improved on ${resolvedIssues.length} ${this.pointsText(resolvedIssues)}`;
        }

        const connector = (newIssues.length > 0 && resolvedIssues.length > 0) ? ' and' : null;

        text = ['Code quality'];
        if (resolvedIssuesText) {
          text.push(resolvedIssuesText);
        }

        if (connector) {
          text.push(connector);
        }

        if (newIssuesText) {
          text.push(newIssuesText);
        }

        text.push('.');
      }

      return text.join('');
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

    handleError() {
      this.isLoading = false;
      this.loadingFailed = true;
    },
  },

  created() {
    const { head_path, base_path } = this.mr.codeclimate;

    this.isLoading = true;

    this.service.fetchCodeclimate(head_path)
      .then(resp => resp.json())
      .then((data) => {
        this.mr.setCodeclimateHeadMetrics(data);
        this.service.fetchCodeclimate(base_path)
          .then(response => response.json())
          .then(baseData => this.mr.setCodeclimateBaseMetrics(baseData))
          .then(() => this.mr.compareCodeclimateMetrics())
          .then(() => {
            this.isLoading = false;
          })
          .catch(() => this.handleError());
      })
      .catch(() => this.handleError());
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
          'ci-status-icon-failed': mr.codeclimateMetrics.newIssues.length,
          'ci-status-icon-passed': mr.codeclimateMetrics.newIssues.length === 0
        }"
        v-html="stateIcon">
      </span>
      <span>
        {{codeText}}
      </span>

      <button
        type="button"
        class="btn-link btn-blank"
        v-if="hasIssues"
        @click="toggleCollapsed">
        {{collapseText}}
      </button>

      <div
        class="code-quality-container"
        v-if="hasIssues"
        v-show="!isCollapsed">
        <issues-block
          class="js-mr-code-resolved-issues"
          v-if="mr.codeclimateMetrics.resolvedIssues.length"
          type="success"
          :issues="mr.codeclimateMetrics.resolvedIssues"
          />

        <issues-block
          class="js-mr-code-new-issues"
          v-if="mr.codeclimateMetrics.newIssues.length"
          type="failed"
          :issues="mr.codeclimateMetrics.newIssues"
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
