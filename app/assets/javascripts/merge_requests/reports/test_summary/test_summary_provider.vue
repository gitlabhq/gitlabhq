<script>
import { computed } from 'vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import { getSlotFunction, normalizeRender } from '~/lib/utils/vue3compat/normalize_render';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import { testReportProjectPipelinePath } from '~/lib/utils/path_helpers/pipelines';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { i18n } from '~/vue_merge_request_widget/widgets/test_report/constants';
import {
  parseTestReport,
  testSummaryStatusIcon,
} from '~/vue_merge_request_widget/widgets/test_report/utils';

export default normalizeRender({
  name: 'TestSummaryProvider',
  provide() {
    return {
      isTestSummaryLoading: computed(() => this.isFetching),
      statusMessage: computed(() => this.statusMessage),
      errorMessage: computed(() => this.errorMessage),
      statusIconName: computed(() => this.statusIconName),
      testReport: computed(() => this.testReport),
      fullReportPath: computed(() => this.fullReportPath),
      headBlobPath: computed(() => this.mr.headBlobPath),
    };
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isFetching: true,
      statusMessage: '',
      errorMessage: '',
      testReport: {},
    };
  },
  computed: {
    fullReportPath() {
      const { project_full_path: projectFullPath, id } = this.mr.pipeline || {};

      return id ? testReportProjectPipelinePath(projectFullPath, id) : '';
    },
    statusIconName() {
      if (this.errorMessage) {
        return EXTENSION_ICONS.error;
      }
      if (this.statusMessage) {
        return EXTENSION_ICONS.warning;
      }
      return testSummaryStatusIcon(this.testReport);
    },
  },
  mounted() {
    this.fetchData();
  },
  beforeDestroy() {
    this.poll?.stop();
  },
  methods: {
    async fetchData() {
      const endpoint = this.mr.testResultsPath;

      if (!endpoint) {
        this.statusMessage = s__('Reports|Test summary results are not available');
        this.isFetching = false;
        return;
      }

      try {
        this.testReport = parseTestReport(await this.fetchWithPolling(endpoint));
      } catch (error) {
        const statusReason = error.response?.data?.status_reason;

        if (statusReason) {
          this.statusMessage = statusReason;
        } else {
          this.errorMessage = i18n.error;
          Sentry.captureException(error);
        }
      }

      this.isFetching = false;
    },
    fetchWithPolling(endpoint) {
      return new Promise((resolve, reject) => {
        this.poll = new Poll({
          resource: { fetchData: () => axios.get(endpoint) },
          method: 'fetchData',
          successCallback: (response) => {
            if (response.status !== HTTP_STATUS_OK) return;

            this.poll.stop();
            resolve(response.data);
          },
          errorCallback: reject,
        });

        this.poll.makeRequest();
      });
    },
  },
  render() {
    return getSlotFunction(this)?.();
  },
});
</script>
