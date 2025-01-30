<script>
import { uniqueId, uniq } from 'lodash';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NO_CONTENT } from '~/lib/utils/http_status';
import TestCaseDetails from '~/ci/pipeline_details/test_reports/test_case_details.vue';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import MrWidgetRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { EXTENSION_ICONS } from '../../constants';
import {
  summaryTextBuilder,
  reportTextBuilder,
  reportSubTextBuilder,
  countRecentlyFailedTests,
  recentFailuresTextBuilder,
  formatFilePath,
} from './utils';
import { i18n, TESTS_FAILED_STATUS, ERROR_STATUS } from './constants';

export default {
  // widget name does not match file path because widget name must match telemetry event names
  // see https://gitlab.com/gitlab-org/gitlab/-/issues/427061
  name: 'WidgetTestSummary',
  components: {
    MrWidget,
    MrWidgetRow,
    DynamicScroller,
    DynamicScrollerItem,
    TestCaseDetails,
  },
  mixins: [glFeatureFlagMixin()],
  i18n,
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      collapsedData: {},
      suites: [],
      modalData: null,
    };
  },
  computed: {
    // show in-progress test report immediately when `mr_show_reports_immediately`
    // feature flag is enabled and the current pipeline is active.
    shouldShowLoading() {
      if (this.mr.isPipelineActive && this.glFeatures.mrShowReportsImmediately) {
        return 'collapsed';
      }

      return undefined;
    },
    failedTestNames() {
      const { data: { suites = [] } = {} } = this.collapsedData;

      if (!this.hasSuites) {
        return '';
      }

      const newFailures = suites.flatMap((suite) => [suite.new_failures || []]);
      const fileNames = newFailures.flatMap((newFailure) => {
        return newFailure.map((failure) => {
          return failure.file;
        });
      });

      return uniq(fileNames).join(' ').trim();
    },
    summary() {
      const { data: { parsingInProgress = false, hasSuiteError = false, summary = {} } = {} } =
        this.collapsedData;

      if (parsingInProgress) {
        return { title: this.$options.i18n.loading };
      }
      if (hasSuiteError) {
        return { title: this.$options.i18n.error };
      }
      return {
        title: summaryTextBuilder(this.$options.i18n.label, summary),
        subtitle: recentFailuresTextBuilder(summary),
      };
    },
    statusIcon() {
      const { data: { status = null, hasSuiteError = false } = {} } = this.collapsedData;

      if (status === TESTS_FAILED_STATUS) {
        return EXTENSION_ICONS.warning;
      }
      if (hasSuiteError) {
        return EXTENSION_ICONS.failed;
      }
      return EXTENSION_ICONS.success;
    },
    tertiaryButtons() {
      const actionButtons = [];

      if (this.failedTestNames.length > 0) {
        actionButtons.push({
          dataClipboardText: this.failedTestNames,
          id: uniqueId('copy-to-clipboard'),
          icon: 'copy-to-clipboard',
          testId: 'copy-failed-specs-btn',
          text: this.$options.i18n.copyFailedSpecs,
          tooltipText: this.$options.i18n.copyFailedSpecsTooltip,
          tooltipOnClick: __('Copied'),
        });
      }

      actionButtons.push({
        text: this.shouldShowLoading
          ? this.$options.i18n.partialReport
          : this.$options.i18n.fullReport,
        href: `${this.mr.pipeline.path}/test_report`,
        target: '_blank',
        trackFullReportClicked: true,
        testId: 'full-report-link',
        tooltipText: this.shouldShowLoading ? this.$options.i18n.partialReportTooltipText : '',
      });

      return actionButtons;
    },
    testResultsPath() {
      return this.mr.testResultsPath;
    },
    hasSuites() {
      return this.suites.length > 0;
    },
  },
  methods: {
    fetchCollapsedData() {
      return axios.get(this.testResultsPath).then((response) => {
        const { data = {}, status } = response;
        const { suites = [], summary = {} } = data;

        this.collapsedData = {
          ...response,
          data: {
            hasSuiteError: suites.some((suite) => suite.status === ERROR_STATUS),
            parsingInProgress: status === HTTP_STATUS_NO_CONTENT,
            ...data,
            summary: {
              recentlyFailed: countRecentlyFailedTests(suites),
              ...summary,
            },
          },
        };
        this.suites = this.prepareSuites(this.collapsedData);
        this.$emit('loaded', summary.failed || 0);

        return response;
      });
    },
    suiteIcon(suite) {
      if (suite.status === ERROR_STATUS) {
        return EXTENSION_ICONS.error;
      }
      if (suite.status === TESTS_FAILED_STATUS) {
        return EXTENSION_ICONS.failed;
      }
      return EXTENSION_ICONS.success;
    },
    testHeader(test, sectionHeader, index) {
      const headers = [];
      if (index === 0) {
        headers.push(sectionHeader);
      }
      if (test.recent_failures?.count && test.recent_failures?.base_branch) {
        headers.push(i18n.recentFailureCount(test.recent_failures));
      }
      return headers;
    },
    mapTestAsChild({ iconName, sectionHeader }) {
      return (test, index) => {
        return {
          id: uniqueId('test-'),
          header: this.testHeader(test, sectionHeader, index),
          text: test.name,
          actions: [
            {
              text: __('View details'),
              onClick: () => {
                this.modalData = {
                  testCase: {
                    filePath: test.file && `${this.mr.headBlobPath}/${formatFilePath(test.file)}`,
                    ...test,
                  },
                };
              },
            },
          ],
          icon: { name: iconName },
        };
      };
    },
    onModalHidden() {
      this.modalData = null;
    },
    prepareSuites(collapsedData) {
      const {
        data: { suites = [] },
      } = collapsedData;

      return suites
        .map((suite) => {
          return {
            ...suite,
            summary: {
              recentlyFailed: countRecentlyFailedTests(suite),
              ...suite.summary,
            },
          };
        })
        .map((suite) => {
          return {
            id: uniqueId('suite-'),
            text: reportTextBuilder(suite),
            subtext: reportSubTextBuilder(suite),
            icon: {
              name: this.suiteIcon(suite),
            },
            children: [
              ...[...suite.new_failures, ...suite.new_errors].map(
                this.mapTestAsChild({
                  sectionHeader: i18n.newHeader,
                  iconName: EXTENSION_ICONS.failed,
                }),
              ),
              ...[...suite.existing_failures, ...suite.existing_errors].map(
                this.mapTestAsChild({
                  iconName: EXTENSION_ICONS.failed,
                }),
              ),
              ...[...suite.resolved_failures, ...suite.resolved_errors].map(
                this.mapTestAsChild({
                  sectionHeader: i18n.fixedHeader,
                  iconName: EXTENSION_ICONS.success,
                }),
              ),
            ],
          };
        });
    },
  },
};
</script>
<template>
  <div>
    <mr-widget
      :error-text="$options.i18n.error"
      :status-icon-name="statusIcon"
      :loading-state="shouldShowLoading"
      :loading-text="$options.i18n.loading"
      :action-buttons="tertiaryButtons"
      :help-popover="$options.helpPopover"
      :widget-name="$options.name"
      :summary="summary"
      :fetch-collapsed-data="fetchCollapsedData"
      :is-collapsible="hasSuites"
    >
      <template #content>
        <mr-widget-row
          v-for="suite in suites"
          :key="suite.id"
          :level="2"
          :status-icon-name="suite.icon.name"
          :widget-name="$options.name"
          data-testid="extension-list-item"
        >
          <template #header>
            <div class="gl-flex-col">
              <div>{{ suite.text }}</div>
              <div
                v-for="(subtext, i) in suite.subtext"
                :key="`${suite.id}-subtext-${i}`"
                class="gl-text-sm gl-text-subtle"
              >
                {{ subtext }}
              </div>
            </div>
          </template>
          <template #body>
            <div v-if="suite.children.length > 0" class="gl-mt-2 gl-w-full">
              <dynamic-scroller
                :items="suite.children"
                :min-item-size="32"
                :style="{ maxHeight: '170px' }"
                key-field="id"
                class="gl-pr-5"
              >
                <template #default="{ item, active }">
                  <dynamic-scroller-item :item="item" :active="active">
                    <strong
                      v-for="(headerText, i) in item.header"
                      :key="`${item.id}-headerText-${i}`"
                      class="gl-mt-2 gl-block"
                    >
                      {{ headerText }}
                    </strong>
                    <mr-widget-row
                      :key="item.id"
                      :level="3"
                      :widget-name="$options.name"
                      :status-icon-name="item.icon.name"
                      :action-buttons="item.actions"
                      class="gl-mt-2"
                    >
                      <template #header>{{ item.text }}</template>
                    </mr-widget-row>
                  </dynamic-scroller-item>
                </template>
              </dynamic-scroller>
            </div>
          </template>
        </mr-widget-row>
      </template>
    </mr-widget>
    <test-case-details
      :modal-id="`modal${$options.name}`"
      :visible="modalData !== null"
      v-bind="modalData"
      @hidden="onModalHidden"
    />
  </div>
</template>
