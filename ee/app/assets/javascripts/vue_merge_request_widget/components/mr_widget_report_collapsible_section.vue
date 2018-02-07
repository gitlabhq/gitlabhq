<script>
  import { __ } from '~/locale';
  import statusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
  import loadingIcon from '~/vue_shared/components/loading_icon.vue';
  import issuesBlock from './mr_widget_report_issues.vue';

  export default {
    name: 'MRWidgetCodeQualityCollapsible',
    components: {
      issuesBlock,
      loadingIcon,
      statusIcon,
    },
    props: {
      // security | codequality | performance | docker
      type: {
        type: String,
        required: true,
      },
      // loading | success | error
      status: {
        type: String,
        required: true,
      },
      loadingText: {
        type: String,
        required: true,
      },
      errorText: {
        type: String,
        required: true,
      },
      successText: {
        type: String,
        required: true,
      },
      unresolvedIssues: {
        type: Array,
        required: false,
        default: () => [],
      },
      resolvedIssues: {
        type: Array,
        required: false,
        default: () => [],
      },
      neutralIssues: {
        type: Array,
        required: false,
        default: () => [],
      },
      allIssues: {
        type: Array,
        required: false,
        default: () => [],
      },
      infoText: {
        type: [String, Boolean],
        required: false,
        default: false,
      },
      hasPriority: {
        type: Boolean,
        required: false,
        default: false,
      },
    },

    data() {
      return {
        collapseText: __('Expand'),
        isCollapsed: true,
        isFullReportVisible: false,
      };
    },

    computed: {
      isLoading() {
        return this.status === 'loading';
      },
      loadingFailed() {
        return this.status === 'error';
      },
      isSuccess() {
        return this.status === 'success';
      },
      statusIconName() {
        if (this.loadingFailed || this.unresolvedIssues.length) {
          return 'warning';
        }
        return 'success';
      },
      hasIssues() {
        return this.unresolvedIssues.length ||
          this.resolvedIssues.length ||
          this.allIssues.length;
      },
    },

    methods: {
      toggleCollapsed() {
        this.isCollapsed = !this.isCollapsed;

        const text = this.isCollapsed ? __('Expand') : __('Collapse');
        this.collapseText = text;
      },
      openFullReport() {
        this.isFullReportVisible = true;
      },
    },
  };
</script>
<template>
  <section class="mr-widget-code-quality mr-widget-section">

    <div
      v-if="isLoading"
      class="media"
    >
      <div
        class="mr-widget-icon"
      >
        <loading-icon />
      </div>
      <div
        class="media-body"
      >
        {{ loadingText }}
      </div>
    </div>

    <div
      v-else-if="isSuccess"
      class="media"
    >
      <status-icon
        :status="statusIconName"
      />

      <div
        class="media-body space-children"
      >
        <span
          class="js-code-text"
        >
          {{ successText }}
        </span>

        <button
          type="button"
          class="btn pull-right btn-sm"
          v-if="hasIssues"
          @click="toggleCollapsed"
        >
          {{ collapseText }}
        </button>
      </div>
    </div>

    <div
      class="code-quality-container"
      v-if="hasIssues"
      v-show="!isCollapsed"
    >

      <p
        v-if="type === 'docker' && infoText"
        v-html="infoText"
        class="js-mr-code-quality-info mr-widget-code-quality-info"
      >
      </p>

      <issues-block
        class="js-mr-code-new-issues"
        v-if="unresolvedIssues.length"
        :type="type"
        status="failed"
        :issues="unresolvedIssues"
        :has-priority="hasPriority"
      />

      <issues-block
        class="js-mr-code-all-issues"
        v-if="isFullReportVisible"
        :type="type"
        status="failed"
        :issues="allIssues"
        :has-priority="hasPriority"
      />

      <issues-block
        class="js-mr-code-non-issues"
        v-if="neutralIssues.length"
        :type="type"
        status="neutral"
        :issues="neutralIssues"
        :has-priority="hasPriority"
      />

      <issues-block
        class="js-mr-code-resolved-issues"
        v-if="resolvedIssues.length"
        :type="type"
        status="success"
        :issues="resolvedIssues"
        :has-priority="hasPriority"
      />

      <button
        v-if="allIssues.length && !isFullReportVisible"
        type="button"
        class="btn-link btn-blank prepend-left-10 js-expand-full-list"
        @click="openFullReport"
      >
        {{ s__("ciReport|Show complete code vulnerabilities report") }}
      </button>
    </div>
    <div
      v-else-if="loadingFailed"
      class="media"
    >
      <status-icon status="notfound" />
      <div class="media-body">
        {{ errorText }}
      </div>
    </div>
  </section>
</template>
