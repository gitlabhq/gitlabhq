<script>
import { __ } from '~/locale';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import IssuesList from './issues_list.vue';
import Popover from './help_popover.vue';
import { LOADING, ERROR, SUCCESS } from '../store/constants';

export default {
  name: 'ReportSection',
  components: {
    IssuesList,
    LoadingIcon,
    StatusIcon,
    Popover,
  },
  props: {
    type: {
      type: String,
      required: false,
      default: '',
    },
    status: {
      type: String,
      required: true,
    },
    loadingText: {
      type: String,
      required: false,
      default: '',
    },
    errorText: {
      type: String,
      required: false,
      default: '',
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
    hasIssues: {
      type: Boolean,
      required: true,
    },
    popoverOptions: {
      type: Object,
      default: () => ({}),
      required: false,
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
      return this.status === LOADING;
    },
    loadingFailed() {
      return this.status === ERROR;
    },
    isSuccess() {
      return this.status === SUCCESS;
    },
    statusIconName() {
      if (this.loadingFailed || this.unresolvedIssues.length || this.neutralIssues.length) {
        return 'warning';
      }
      return 'success';
    },
    headerText() {
      if (this.isLoading) {
        return this.loadingText;
      }

      if (this.isSuccess) {
        return this.successText;
      }

      if (this.loadingFailed) {
        return this.errorText;
      }

      return '';
    },
    hasPopover() {
      return Object.keys(this.popoverOptions).length > 0;
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
  <section>
    <div
      class="media prepend-top-default prepend-left-default
 append-right-default append-bottom-default"
    >
      <loading-icon
        class="mr-widget-icon"
        v-if="isLoading"
      />
      <status-icon
        v-else
        :status="statusIconName"
      />
      <div
        class="media-body space-children"
      >
        <span
          class="js-code-text code-text"
        >
          {{ headerText }}

          <popover
            v-if="hasPopover"
            class="prepend-left-5"
            :options="popoverOptions"
          />
        </span>

        <button
          type="button"
          class="js-collapse-btn btn bt-default pull-right btn-sm"
          v-if="hasIssues"
          @click="toggleCollapsed"
        >
          {{ collapseText }}
        </button>
      </div>
    </div>

    <div
      class="js-report-section-container"
      v-if="hasIssues"
      v-show="!isCollapsed"
    >
      <slot name="body">
        <issues-list
          :unresolved-issues="unresolvedIssues"
          :resolved-issues="resolvedIssues"
          :all-issues="allIssues"
          :type="type"
          :is-full-report-visible="isFullReportVisible"
        />

        <button
          v-if="allIssues.length && !isFullReportVisible"
          type="button"
          class="btn-link btn-blank prepend-left-10 js-expand-full-list break-link"
          @click="openFullReport"
        >
          {{ s__("ciReport|Show complete code vulnerabilities report") }}
        </button>
      </slot>
    </div>
  </section>
</template>
