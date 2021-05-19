<script>
import { GlButton } from '@gitlab/ui';
import api from '~/api';
import { __ } from '~/locale';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import Popover from '~/vue_shared/components/help_popover.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { status, SLOT_SUCCESS, SLOT_LOADING, SLOT_ERROR } from '../constants';
import IssuesList from './issues_list.vue';

export default {
  name: 'ReportSection',
  components: {
    GlButton,
    IssuesList,
    Popover,
    StatusIcon,
  },
  mixins: [glFeatureFlagsMixin()],
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
    shouldEmitToggleEvent: {
      type: Boolean,
      required: false,
      default: false,
    },
    trackAction: {
      type: String,
      required: false,
      default: null,
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
        return SLOT_SUCCESS;
      } else if (this.isLoading) {
        return SLOT_LOADING;
      }

      return SLOT_ERROR;
    },
  },
  methods: {
    toggleCollapsed() {
      if (this.trackAction && this.glFeatures.usersExpandingWidgetsUsageData) {
        api.trackRedisHllUserEvent(this.trackAction);
      }

      if (this.shouldEmitToggleEvent) {
        this.$emit('toggleEvent');
      }
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
        <div data-testid="report-section-code-text" class="js-code-text code-text">
          <div class="gl-display-flex gl-align-items-center">
            <p class="gl-line-height-normal gl-m-0">{{ headerText }}</p>
            <slot :name="slotName"></slot>
            <popover
              v-if="hasPopover"
              :options="popoverOptions"
              class="gl-ml-2 gl-display-inline-flex"
            />
          </div>
          <slot name="sub-heading"></slot>
        </div>

        <slot name="action-buttons" :is-collapsible="isCollapsible"></slot>

        <gl-button
          v-if="isCollapsible"
          class="js-collapse-btn"
          data-testid="report-section-expand-button"
          data-qa-selector="expand_report_button"
          @click="toggleCollapsed"
        >
          {{ collapseText }}
        </gl-button>
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
