<script>
import { __ } from '~/locale';
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import IssuesList from './issues_list.vue';
import Popover from './help_popover.vue';

const LOADING = 'LOADING';
const ERROR = 'ERROR';
const SUCCESS = 'SUCCESS';

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
      isCollapsed: true,
    };
  },

  computed: {
    collapseText() {
      return this.isCollapsed ? __('Expand') : __('Collapse');
    },
    isLoading() {
      return this.status === LOADING;
    },
    loadingFailed() {
      return this.status === ERROR;
    },
    isSuccess() {
      return this.status === SUCCESS;
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
    <div
      class="media"
    >
      <status-icon
        :status="statusIconName"
      />
      <div
        class="media-body space-children d-flex flex-align-self-center"
      >
        <span
          class="js-code-text code-text"
        >
          {{ headerText }}

          <popover
            v-if="hasPopover"
            :options="popoverOptions"
            class="prepend-left-5"
          />
        </span>

        <button
          v-if="isCollapsible"
          type="button"
          class="js-collapse-btn btn bt-default float-right btn-sm"
          @click="toggleCollapsed"
        >
          {{ collapseText }}
        </button>
      </div>
    </div>

    <div
      v-if="hasIssues"
      v-show="isExpanded"
      class="js-report-section-container"
    >
      <slot name="body">
        <issues-list
          :unresolved-issues="unresolvedIssues"
          :resolved-issues="resolvedIssues"
          :neutral-issues="neutralIssues"
          :all-issues="allIssues"
          :component="component"
        />
      </slot>
    </div>
  </section>
</template>
