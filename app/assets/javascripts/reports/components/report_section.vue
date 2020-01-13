<script>
import { __ } from '~/locale';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import Popover from '~/vue_shared/components/help_popover.vue';
import IssuesList from './issues_list.vue';
import { status } from '../constants';

export default {
  name: 'ReportSection',
  components: {
    IssuesList,
    StatusIcon,
    Popover,
  },
  props: {
    alwaysOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
    component: {
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
      required: false,
      default: '',
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
    showReportSectionStatusIcon: {
      type: Boolean,
      required: false,
      default: true,
    },
    issuesUlElementClass: {
      type: String,
      required: false,
      default: undefined,
    },
    issuesListContainerClass: {
      type: String,
      required: false,
      default: undefined,
    },
    issueItemClass: {
      type: String,
      required: false,
      default: undefined,
    },
  },

  data() {
    return {
      isCollapsed: true,
    };
  },

  computed: {
    collapseText() {
      return this.isCollapsed ? __('Expand') : __('Collapse');
    },
    isLoading() {
      return this.status === status.LOADING;
    },
    loadingFailed() {
      return this.status === status.ERROR;
    },
    isSuccess() {
      return this.status === status.SUCCESS;
    },
    isCollapsible() {
      return !this.alwaysOpen && this.hasIssues;
    },
    isExpanded() {
      return this.alwaysOpen || !this.isCollapsed;
    },
    statusIconName() {
      if (this.isLoading) {
        return 'loading';
      }
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
    slotName() {
      if (this.isSuccess) {
        return 'success';
      } else if (this.isLoading) {
        return 'loading';
      }

      return 'error';
    },
  },
  methods: {
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
    },
  },
};
</script>
<template>
  <section class="media-section">
    <div class="media">
      <status-icon :status="statusIconName" :size="24" class="align-self-center" />
      <div class="media-body d-flex flex-align-self-center align-items-center">
        <div class="js-code-text code-text">
          <div>
            {{ headerText }}
            <slot :name="slotName"></slot>
            <popover v-if="hasPopover" :options="popoverOptions" class="prepend-left-5" />
          </div>
          <slot name="subHeading"></slot>
        </div>

        <slot name="actionButtons"></slot>

        <button
          v-if="isCollapsible"
          type="button"
          class="js-collapse-btn btn float-right btn-sm align-self-center qa-expand-report-button"
          @click="toggleCollapsed"
        >
          {{ collapseText }}
        </button>
      </div>
    </div>

    <div v-if="hasIssues" v-show="isExpanded" class="js-report-section-container">
      <slot name="body">
        <issues-list
          :unresolved-issues="unresolvedIssues"
          :resolved-issues="resolvedIssues"
          :neutral-issues="neutralIssues"
          :component="component"
          :show-report-section-status-icon="showReportSectionStatusIcon"
          :issues-ul-element-class="issuesUlElementClass"
          :class="issuesListContainerClass"
          :issue-item-class="issueItemClass"
        />
      </slot>
    </div>
  </section>
</template>
