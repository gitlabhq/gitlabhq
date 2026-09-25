<script>
import { computed } from 'vue';
import { s__ } from '~/locale';
import { getSlotFunction, normalizeRender } from '~/lib/utils/vue3compat/normalize_render';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import {
  terraformInvalidCount,
  terraformRows,
  terraformSummary,
} from '~/vue_merge_request_widget/widgets/terraform/utils';
import Poll from '~/lib/utils/poll';

export default normalizeRender({
  name: 'TerraformProvider',
  provide() {
    return {
      isTerraformLoading: computed(() => this.isFetching),
      statusMessage: computed(() => this.statusMessage),
      reportSummary: computed(() => this.reportSummary),
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
      hasError: false,
      responseData: null,
    };
  },
  computed: {
    reportSummary() {
      return terraformSummary(this.responseData);
    },
    sections() {
      const rows = terraformRows(this.responseData, { plainSupportingText: true });

      return rows.length ? [{ children: rows }] : [];
    },
    statusIconName() {
      if (this.hasError) {
        return EXTENSION_ICONS.error;
      }
      if (this.statusMessage || terraformInvalidCount(this.responseData) > 0) {
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
      const endpoint = this.mr.terraformReportsPath;

      try {
        const data = endpoint ? await this.fetchWithPolling(endpoint) : null;

        if (data) {
          this.responseData = data;
        } else {
          this.statusMessage = s__('Terraform|Terraform reports are not available');
        }
      } catch (error) {
        const statusReason = error.response?.data?.status_reason;

        this.statusMessage = statusReason || s__('Terraform|Failed to load Terraform reports');
        this.hasError = !statusReason;
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
