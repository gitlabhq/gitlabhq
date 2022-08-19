<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { sprintf, __ } from '~/locale';
import Poll from '~/lib/utils/poll';
import StatusIcon from '../extensions/status_icon.vue';
import { EXTENSION_ICONS } from '../../constants';

const FETCH_TYPE_COLLAPSED = 'collapsed';

export default {
  components: {
    StatusIcon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
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
      required: false,
      default: __('Loading'),
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
    statusIconName: {
      type: String,
      default: 'neutral',
      required: false,
      validator: (value) => Object.keys(EXTENSION_ICONS).indexOf(value) > -1,
    },
    isCollapsible: {
      type: Boolean,
      required: true,
    },
    widgetName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isCollapsed: true,
      isLoading: false,
      error: null,
    };
  },
  computed: {
    collapseButtonLabel() {
      return sprintf(this.isCollapsed ? __('Show details') : __('Hide details'));
    },
    statusIcon() {
      return this.error ? EXTENSION_ICONS.failed : this.statusIconName;
    },
  },
  watch: {
    isLoading(newValue) {
      this.$emit('is-loading', newValue);
    },
  },
  async mounted() {
    this.isLoading = true;

    try {
      await this.fetch(this.fetchCollapsedData, FETCH_TYPE_COLLAPSED);
    } catch {
      this.error = this.errorText;
    }

    this.isLoading = false;
  },
  methods: {
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
    },
    fetch(handler, dataType) {
      const requests = this.multiPolling ? handler() : [handler];

      const promises = requests.map((request) => {
        return new Promise((resolve, reject) => {
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

              resolve(response.data);
            },
            errorCallback: (e) => {
              Sentry.captureException(e);
              reject(e);
            },
          });

          poll.makeRequest();
        });
      });

      return Promise.all(promises).then((data) => {
        this.$emit('input', { ...this.value, [dataType]: this.multiPolling ? data : data[0] });
      });
    },
  },
};
</script>

<template>
  <section class="media-section" data-testid="widget-extension">
    <div class="media gl-p-5">
      <status-icon :level="1" :name="widgetName" :is-loading="isLoading" :icon-name="statusIcon" />
      <div
        class="media-body gl-display-flex gl-flex-direction-row! gl-align-self-center"
        data-testid="widget-extension-top-level"
      >
        <div class="gl-flex-grow-1" data-testid="widget-extension-top-level-summary">
          <slot v-if="!error" name="summary">{{ isLoading ? loadingText : summary }}</slot>
          <span v-else>{{ error }}</span>
        </div>
        <!-- actions will go here -->
        <div
          v-if="isCollapsible"
          class="gl-border-l-1 gl-border-l-solid gl-border-gray-100 gl-ml-3 gl-pl-3 gl-h-6"
        >
          <gl-button
            v-gl-tooltip
            :title="collapseButtonLabel"
            :aria-expanded="`${!isCollapsed}`"
            :aria-label="collapseButtonLabel"
            :icon="isCollapsed ? 'chevron-lg-down' : 'chevron-lg-up'"
            category="tertiary"
            data-testid="toggle-button"
            size="small"
            @click="toggleCollapsed"
          />
        </div>
      </div>
    </div>
    <div
      v-if="!isCollapsed"
      class="mr-widget-grouped-section gl-relative"
      data-testid="widget-extension-collapsed-section"
    >
      <slot name="content">{{ content }}</slot>
    </div>
  </section>
</template>
