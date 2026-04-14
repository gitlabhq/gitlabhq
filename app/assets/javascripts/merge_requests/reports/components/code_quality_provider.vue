<script>
import { computed } from 'vue';
import { s__ } from '~/locale';
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import {
  transformNewCodeQualityFinding,
  transformResolvedCodeQualityFinding,
} from '~/vue_merge_request_widget/widgets/code_quality/utils';
import Poll from '~/lib/utils/poll';

export default normalizeRender({
  name: 'CodeQualityProvider',
  provide() {
    return {
      isCodeQualityLoading: computed(() => this.isFetching),
      errorMessage: computed(() => this.errorMessage),
      statusMessage: computed(() => this.statusMessage),
      newErrorsCount: computed(() => this.newErrorsCount),
      resolvedErrorsCount: computed(() => this.resolvedErrorsCount),
      statusIconName: computed(() => this.statusIconName),
      sections: computed(() => this.sections),
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
      responseData: null,
      activePolls: [],
    };
  },
  computed: {
    codeQualityEndpoint() {
      return this.mr.codequalityReportsPath;
    },
    newErrorsCount() {
      return this.responseData?.new_errors?.length || 0;
    },
    resolvedErrorsCount() {
      return this.responseData?.resolved_errors?.length || 0;
    },
    sections() {
      const newErrors = this.responseData?.new_errors || [];
      const resolvedErrors = this.responseData?.resolved_errors || [];
      const children = [
        ...newErrors.map(transformNewCodeQualityFinding),
        ...resolvedErrors.map(transformResolvedCodeQualityFinding),
      ];
      if (!children.length) return [];
      return [{ children }];
    },
    statusIconName() {
      if (this.errorMessage) {
        return EXTENSION_ICONS.error;
      }
      if (this.statusMessage || this.newErrorsCount > 0) {
        return EXTENSION_ICONS.warning;
      }
      return EXTENSION_ICONS.success;
    },
  },
  mounted() {
    this.fetchData();
  },
  beforeDestroy() {
    this.stopAllPolls();
  },
  methods: {
    async fetchData() {
      if (!this.codeQualityEndpoint) {
        this.statusMessage = s__('ciReport|Code quality results are not available');
        this.isFetching = false;
        return;
      }

      try {
        const data = await this.fetchWithPolling(this.codeQualityEndpoint);
        if (data) {
          this.responseData = data;
        }
      } catch (error) {
        const statusReason = error.response?.data?.status_reason;
        if (statusReason) {
          this.statusMessage = statusReason;
        } else {
          this.errorMessage = s__('ciReport|Code quality failed loading results');
        }
      }

      this.isFetching = false;
    },
    fetchWithPolling(endpoint) {
      return new Promise((resolve, reject) => {
        const poll = new Poll({
          resource: {
            fetchData: () => axios.get(endpoint),
          },
          method: 'fetchData',
          successCallback: (response) => {
            const headers = normalizeHeaders(response.headers);

            if (headers['POLL-INTERVAL']) {
              return;
            }

            poll.stop();
            resolve(response.data);
          },
          errorCallback: (error) => {
            reject(error);
          },
        });

        poll.makeRequest();
        this.activePolls.push(poll);
      });
    },
    stopAllPolls() {
      this.activePolls.forEach((poll) => poll.stop());
      this.activePolls = [];
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
});
</script>
