import { uniqueId } from 'lodash';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NO_CONTENT } from '~/lib/utils/http_status';
import TestCaseDetails from '~/pipelines/components/test_reports/test_case_details.vue';
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
  name: 'WidgetTestSummary',
  enablePolling: true,
  i18n,
  props: ['testResultsPath', 'headBlobPath', 'pipeline'],
  modalComponent: TestCaseDetails,
  computed: {
    failedTestNames() {
      if (!this.collapsedData?.suites) {
        return '';
      }

      const newFailures = this.collapsedData?.suites.flatMap((suite) => [suite.new_failures || []]);
      const fileNames = newFailures.flatMap((newFailure) => {
        return newFailure.map((failure) => {
          return failure.file;
        });
      });

      return fileNames.join(' ').trim();
    },
    summary(data) {
      if (data.parsingInProgress) {
        return this.$options.i18n.loading;
      }
      if (data.hasSuiteError) {
        return this.$options.i18n.error;
      }
      return {
        subject: summaryTextBuilder(this.$options.i18n.label, data.summary),
        meta: recentFailuresTextBuilder(data.summary),
      };
    },
    statusIcon(data) {
      if (data.status === TESTS_FAILED_STATUS) {
        return EXTENSION_ICONS.warning;
      }
      if (data.hasSuiteError) {
        return EXTENSION_ICONS.failed;
      }
      return EXTENSION_ICONS.success;
    },
    tertiaryButtons() {
      const actionButtons = [];

      if (this.failedTestNames().length > 0) {
        actionButtons.push({
          dataClipboardText: this.failedTestNames(),
          id: uniqueId('copy-to-clipboard'),
          icon: 'copy-to-clipboard',
          testId: 'copy-failed-specs-btn',
          text: this.$options.i18n.copyFailedSpecs,
          tooltipText: this.$options.i18n.copyFailedSpecsTooltip,
          tooltipOnClick: __('Copied'),
        });
      }

      actionButtons.push({
        text: this.$options.i18n.fullReport,
        href: `${this.pipeline.path}/test_report`,
        target: '_blank',
        trackFullReportClicked: true,
        testId: 'full-report-link',
      });

      return actionButtons;
    },
  },
  methods: {
    fetchCollapsedData() {
      return axios.get(this.testResultsPath).then((response) => {
        const { data = {}, status } = response;
        const { suites = [], summary = {} } = data;

        return {
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
      });
    },
    fetchFullData() {
      return Promise.resolve(this.prepareReports());
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
          modal: {
            text: test.name,
            onClick: () => {
              this.modalData = {
                testCase: {
                  filePath: test.file && `${this.headBlobPath}/${formatFilePath(test.file)}`,
                  ...test,
                },
              };
            },
          },
          icon: { name: iconName },
        };
      };
    },
    prepareReports() {
      return this.collapsedData.suites
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
