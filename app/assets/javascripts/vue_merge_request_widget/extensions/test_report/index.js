import { uniqueId } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { EXTENSION_ICONS } from '../../constants';
import { summaryTextBuilder, reportTextBuilder, reportSubTextBuilder } from './utils';
import { i18n, TESTS_FAILED_STATUS, ERROR_STATUS } from './constants';

export default {
  name: 'WidgetTestSummary',
  enablePolling: true,
  i18n,
  expandEvent: 'i_testing_summary_widget_total',
  props: ['testResultsPath', 'headBlobPath', 'pipeline'],
  computed: {
    summary(data) {
      if (data.parsingInProgress) {
        return this.$options.i18n.loading;
      }
      if (data.hasSuiteError) {
        return this.$options.i18n.error;
      }
      return summaryTextBuilder(this.$options.i18n.label, data.summary);
    },
    statusIcon(data) {
      if (data.parsingInProgress) {
        return null;
      }
      if (data.status === TESTS_FAILED_STATUS) {
        return EXTENSION_ICONS.warning;
      }
      if (data.hasSuiteError) {
        return EXTENSION_ICONS.failed;
      }
      return EXTENSION_ICONS.success;
    },
    tertiaryButtons() {
      return [
        {
          text: this.$options.i18n.fullReport,
          href: `${this.pipeline.path}/test_report`,
          target: '_blank',
        },
      ];
    },
  },
  methods: {
    fetchCollapsedData() {
      return axios.get(this.testResultsPath).then(({ data = {}, status }) => {
        return {
          data: {
            hasSuiteError: data.suites?.some((suite) => suite.status === ERROR_STATUS),
            parsingInProgress: status === 204,
            ...data,
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
    prepareReports() {
      return this.collapsedData.suites.map((suite) => {
        return {
          id: uniqueId('suite-'),
          text: reportTextBuilder(suite),
          subtext: reportSubTextBuilder(suite),
          icon: {
            name: this.suiteIcon(suite),
          },
        };
      });
    },
  },
};
