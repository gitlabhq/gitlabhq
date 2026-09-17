<script>
import { computed } from 'vue';
import { s__ } from '~/locale';
import { getSlotFunction, normalizeRender } from '~/lib/utils/vue3compat/normalize_render';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import {
  accessibilityErrorCount,
  accessibilitySections,
} from '~/vue_merge_request_widget/widgets/accessibility/utils';
import Poll from '~/lib/utils/poll';

export default normalizeRender({
  name: 'AccessibilityProvider',
  provide() {
    return {
      isAccessibilityLoading: computed(() => this.isFetching),
      errorMessage: computed(() => this.errorMessage),
      statusMessage: computed(() => this.statusMessage),
      errorCount: computed(() => this.errorCount),
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
    };
  },
  computed: {
    errorCount() {
      return accessibilityErrorCount(this.responseData);
    },
    sections() {
      return accessibilitySections(this.responseData);
    },
    statusIconName() {
      if (this.errorMessage) {
        return EXTENSION_ICONS.error;
      }
      if (this.statusMessage || this.errorCount > 0) {
        return EXTENSION_ICONS.warning;
      }
      return EXTENSION_ICONS.success;
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
      const endpoint = this.mr.accessibilityReportPath;

      try {
        // An empty body means the merge request has no report, not an empty one.
        const data = endpoint ? await this.fetchWithPolling(endpoint) : null;

        if (data) {
          this.responseData = data;
        } else {
          this.statusMessage = s__('Reports|Accessibility scanning results are not available');
        }
      } catch (error) {
        const statusReason = error.response?.data?.status_reason;

        if (statusReason) {
          this.statusMessage = statusReason;
        } else {
          this.errorMessage = s__('Reports|Accessibility scanning failed loading results');
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
            if (normalizeHeaders(response.headers)['POLL-INTERVAL']) return;

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
