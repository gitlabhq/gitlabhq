<script>
import statusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import '~/lib/utils/text_utility';
import issuesBlock from './mr_widget_code_quality_issues.vue';

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
    statusIcon,
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
    status() {
      if (this.loadingFailed || this.mr.codeclimateMetrics.newIssues.length) {
        return 'failed';
      }
      return 'success';
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
        text.push('No changes to code quality');
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
  <section class="mr-widget-code-quality mr-widget-section">

    <div
      v-if="isLoading"
      class="media">
      <div class="mr-widget-icon">
        <i
          class="fa fa-spinner fa-spin"
          aria-hidden="true">
        </i>
      </div>
      <div class="media-body">
        Loading codeclimate report
      </div>
    </div>

    <div
      v-else-if="!isLoading && !loadingFailed"
      class="media">
      <status-icon :status="status" />
      <div class="media-body space-children">
        <span class="js-code-text">
          {{codeText}}
        </span>

        <button
          type="button"
          class="btn-link btn-blank"
          v-if="hasIssues"
          @click="toggleCollapsed">
          {{collapseText}}
        </button>
      </div>
      </div>

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
    <div
      v-else-if="loadingFailed"
      class="media">
      <status-icon status="failed" />
      <div class="media-body">
        Failed to load codeclimate report
      </div>
    </div>
  </section>
</template>
