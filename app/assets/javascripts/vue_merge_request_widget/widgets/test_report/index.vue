<script>
import { uniqueId } from 'lodash-es';
import { __, s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NO_CONTENT } from '~/lib/utils/http_status';
import { joinPaths } from '~/lib/utils/url_utility';
import {
  TEST_SUMMARY_ROUTE,
  CLICK_VIEW_REPORT_ON_MERGE_REQUEST_WIDGET,
  TRACKING_LABEL_BY_ROUTE,
} from '~/merge_requests/reports/constants';
import { InternalEvents } from '~/tracking';
import TestCaseDetails from '~/ci/pipeline_details/test_reports/test_case_details.vue';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import MrWidgetRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import { testReportProjectPipelinePath } from '~/lib/utils/path_helpers/pipelines';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import { EXTENSION_ICONS } from '../../constants';
import {
  reportTextBuilder,
  reportSubTextBuilder,
  countRecentlyFailedTests,
  formatFilePath,
  failedTestFiles,
  parseTestReport,
  testSummary,
  testSummaryStatusIcon,
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
  i18n,
  mixins: [InternalEvents.mixin()],
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  emits: ['loaded'],
  data() {
    return {
      collapsedData: {},
      suites: [],
      modalData: null,
    };
  },
  computed: {
    shouldShowLoading() {
      if (this.mr.isPipelineActive) {
        return 'collapsed';
      }

      return undefined;
    },
    failedTestNames() {
      if (!this.hasSuites) {
        return '';
      }

      return failedTestFiles(this.collapsedData.data?.suites);
    },
    summary() {
      if (this.collapsedData.data?.parsingInProgress) {
        return { title: this.$options.i18n.loading };
      }
      return testSummary(this.collapsedData.data);
    },
    statusIcon() {
      return testSummaryStatusIcon(this.collapsedData.data);
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
        href:
          this.mr.pipeline?.project_full_path && this.mr.pipeline?.id
            ? testReportProjectPipelinePath(this.mr.pipeline.project_full_path, this.mr.pipeline.id)
            : undefined,
        target: '_blank',
        trackFullReportClicked: true,
        testId: 'full-report-link',
        tooltipText: this.shouldShowLoading ? this.$options.i18n.partialReportTooltipText : '',
      });

      if (this.hasReportsTab) {
        actionButtons.push({
          text: s__('MrReports|View report'),
          href: joinPaths(this.mr.reportsTabPath, TEST_SUMMARY_ROUTE),
          onClick: (action, e) => {
            e.preventDefault();
            this.trackEvent(CLICK_VIEW_REPORT_ON_MERGE_REQUEST_WIDGET, {
              label: TRACKING_LABEL_BY_ROUTE[TEST_SUMMARY_ROUTE],
            });
            window.history.pushState(null, null, action.href);
            window.dispatchEvent(new PopStateEvent('popstate'));
          },
        });
      }

      return actionButtons;
    },
    testResultsPath() {
      return this.mr.testResultsPath;
    },
    hasSuites() {
      return this.suites.length > 0;
    },
    hasReportsTab() {
      return Boolean(this.mr.reportsTabPath) && !this.shouldShowLoading;
    },
  },
  methods: {
    fetchCollapsedData() {
      return axios.get(this.testResultsPath).then((response) => {
        const { data = {}, status } = response;

        this.collapsedData = {
          ...response,
          data: {
            parsingInProgress: status === HTTP_STATUS_NO_CONTENT,
            ...parseTestReport(data),
          },
        };
        this.suites = this.prepareSuites(this.collapsedData);
        this.$emit('loaded', data.summary?.failed || 0);

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
      :is-collapsible="!hasReportsTab && hasSuites"
      :expand-button-label="s__('Reports|Expand test summary')"
      :collapse-button-label="s__('Reports|Collapse test summary')"
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
