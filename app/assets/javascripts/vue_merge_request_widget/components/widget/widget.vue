<script>
import * as Sentry from '@sentry/browser';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import Poll from '~/lib/utils/poll';

const FETCH_TYPE_COLLAPSED = 'collapsed';
// const FETCH_TYPE_EXPANDED = 'expanded';

export default {
  props: {
    /**
     * @param {value.collapsed} Object
     * @param {value.extended} Object
     */
    value: {
      type: Object,
      required: true,
    },
    loadingText: {
      type: String,
      required: true,
    },
    errorText: {
      type: String,
      required: false,
      default: __('Failed to load'),
    },
    fetchCollapsedData: {
      type: Function,
      required: true,
    },
    fetchExtendedData: {
      type: Function,
      required: false,
      default: undefined,
    },
    // If the summary slot is not used, this value will be used as a fallback.
    summary: {
      type: String,
      required: false,
      default: undefined,
    },
    // If the content slot is not used, this value will be used as a fallback.
    content: {
      type: Object,
      required: false,
      default: undefined,
    },
    multiPolling: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      loading: false,
      statusIcon: null,
      error: null,
    };
  },
  async mounted() {
    this.loading = true;

    try {
      await this.fetch(this.fetchCollapsedData, FETCH_TYPE_COLLAPSED);
    } catch {
      this.error = this.errorText;
    }

    this.loading = false;
  },
  methods: {
    fetch(handler, dataType) {
      const requests = this.multiPolling ? handler() : [handler];
      const allData = [];

      const promises = requests.map((request) => {
        return new Promise((resolve, reject) => {
          const setData = (data) => {
            this.$emit('input', { ...this.value, [dataType]: data });
            resolve(data);
          };

          const poll = new Poll({
            resource: {
              fetchData: () => request(),
            },
            method: 'fetchData',
            successCallback: (response) => {
              const headers = normalizeHeaders(response.headers);

              if (headers['POLL-INTERVAL']) {
                return;
              }

              if (this.multiPolling) {
                allData.push(response.data);

                if (allData.length === requests.length) {
                  setData(allData);
                }

                return;
              }

              setData(response.data);
            },
            errorCallback: (e) => {
              Sentry.captureException(e);
              reject(e);
            },
          });

          poll.makeRequest();
        });
      });

      return Promise.all(promises);
    },
  },
};
</script>

<template>
  <section class="media-section" data-testid="widget-extension">
    <div class="media gl-p-5">
      <!-- status icon will go here -->
      <div
        class="media-body gl-display-flex gl-flex-direction-row! gl-align-self-center"
        data-testid="widget-extension-top-level"
      >
        <div class="gl-flex-grow-1" data-testid="widget-extension-top-level-summary">
          <slot name="summary">{{ summary }}</slot>
        </div>
        <!-- actions will go here -->
        <!-- toggle button will go here -->
      </div>
    </div>
    <div
      class="mr-widget-grouped-section gl-relative"
      data-testid="widget-extension-collapsed-section"
    >
      <slot name="content">{{ content }}</slot>
    </div>
  </section>
</template>
