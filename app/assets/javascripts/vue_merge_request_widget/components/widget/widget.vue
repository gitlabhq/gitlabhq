<script>
import { GlButton, GlLink, GlTooltipDirective, GlLoadingIcon } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { logError } from '~/lib/logger';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { sprintf, __ } from '~/locale';
import Poll from '~/lib/utils/poll';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import { EXTENSION_ICONS } from '../../constants';
import { createTelemetryHub } from '../extensions/telemetry';
import ContentRow from './widget_content_row.vue';
import DynamicContent from './dynamic_content.vue';
import StatusIcon from './status_icon.vue';
import ActionButtons from './action_buttons.vue';

const FETCH_TYPE_COLLAPSED = 'collapsed';
const FETCH_TYPE_EXPANDED = 'expanded';
const WIDGET_PREFIX = 'Widget';
const MISSING_RESPONSE_HEADERS =
  'MR Widget: raesponse object should contain status and headers object. Make sure to include that in your `fetchCollapsedData` and `fetchExpandedData` functions.';

export default {
  MISSING_RESPONSE_HEADERS,

  components: {
    ActionButtons,
    StatusIcon,
    GlLink,
    GlButton,
    GlLoadingIcon,
    ContentRow,
    DynamicContent,
    DynamicScroller,
    DynamicScrollerItem,
    HelpPopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    /**
     * @param {value.collapsed} Object
     * @param {value.expanded} Object
     */
    value: {
      type: Object,
      required: false,
      default: () => ({}),
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
      required: false,
      default: undefined,
    },
    fetchExpandedData: {
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
      type: Array,
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
      required: false,
      default: 'neutral',
      validator: (value) => Object.keys(EXTENSION_ICONS).indexOf(value) > -1,
    },
    isCollapsible: {
      type: Boolean,
      required: true,
    },
    /**
     * A button is composed of the following properties:
     *
     * {
     *   "id": string,
     *   "href": string,
     *   "dataMethod": string,
     *   "dataClipboardText": string,
     *   "icon": string,
     *   "variant": string,
     *   "loading": boolean,
     *   "testId":string,
     *   "text": string,
     *   "class": string | Object,
     *   "trackFullReportClicked": boolean,
     * }
     */
    actionButtons: {
      type: Array,
      required: false,
      default: () => [],
    },
    widgetName: {
      type: String,
      required: true,
      // see https://docs.gitlab.com/ee/development/fe_guide/merge_request_widget_extensions.html#add-new-widgets
      validator: (val) => val.startsWith(WIDGET_PREFIX),
    },
    telemetry: {
      type: Boolean,
      required: false,
      default: true,
    },
    /**
     * @typedef {Object} helpPopover
     * @property {Object} options
     * @property {String} options.title
     * @property {Object} content
     * @property {String} content.text
     * @property {String} content.learnMorePath
     */
    helpPopover: {
      type: Object,
      required: false,
      default: null,
    },
    // When this is provided, the widget will display an error message in the summary section.
    hasError: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isExpandedForTheFirstTime: true,
      isCollapsed: true,
      isLoading: false,
      isLoadingExpandedContent: false,
      summaryError: null,
      contentError: null,
      telemetryHub: null,
    };
  },
  computed: {
    collapseButtonLabel() {
      return sprintf(this.isCollapsed ? __('Show details') : __('Hide details'));
    },
    summaryStatusIcon() {
      return this.summaryError ? this.$options.failedStatusIcon : this.statusIconName;
    },
    hasActionButtons() {
      return this.actionButtons.length > 0 || Boolean(this.$scopedSlots['action-buttons']);
    },
  },
  watch: {
    hasError: {
      handler(newValue) {
        this.summaryError = newValue ? this.errorText : null;
      },
      immediate: true,
    },
    isLoading(newValue) {
      this.$emit('is-loading', newValue);
    },
  },
  created() {
    if (this.telemetry) {
      this.telemetryHub = createTelemetryHub(this.widgetName);
    }
  },
  async mounted() {
    this.isLoading = true;
    this.telemetryHub?.viewed();

    try {
      if (this.fetchCollapsedData) {
        await this.fetch(this.fetchCollapsedData, FETCH_TYPE_COLLAPSED);
      }
    } catch {
      this.summaryError = this.errorText;
    }

    this.isLoading = false;
  },
  methods: {
    onActionClick(action) {
      if (action.trackFullReportClicked) {
        this.telemetryHub?.fullReportClicked();
      }
    },
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;

      if (this.isExpandedForTheFirstTime) {
        this.telemetryHub?.expanded({ type: this.summaryStatusIcon });

        if (typeof this.fetchExpandedData === 'function') {
          this.isExpandedForTheFirstTime = false;
          this.fetchExpandedContent();
        }
      }

      this.$emit('toggle', { expanded: !this.isCollapsed });
    },
    async fetchExpandedContent() {
      this.isLoadingExpandedContent = true;
      this.contentError = null;

      try {
        await this.fetch(this.fetchExpandedData, FETCH_TYPE_EXPANDED);
      } catch {
        this.contentError = this.errorText;

        // Reset these values so that we allow refetching
        this.isExpandedForTheFirstTime = true;
        this.isCollapsed = true;
      }

      this.isLoadingExpandedContent = false;
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
              if (
                typeof response.status === 'undefined' ||
                typeof response.headers === 'undefined'
              ) {
                logError(MISSING_RESPONSE_HEADERS);
                throw new Error(MISSING_RESPONSE_HEADERS);
              }

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
  failedStatusIcon: EXTENSION_ICONS.failed,
  i18n: {
    learnMore: __('Learn more'),
  },
};
</script>

<template>
  <section class="media-section" data-testid="widget-extension">
    <div class="gl-px-5 gl-pr-4 gl-py-4 gl-align-items-center gl-display-flex">
      <status-icon
        :level="1"
        :name="widgetName"
        :is-loading="isLoading"
        :icon-name="summaryStatusIcon"
      />
      <div
        class="media-body gl-display-flex gl-flex-direction-row! gl-align-self-center"
        data-testid="widget-extension-top-level"
      >
        <div class="gl-flex-grow-1" data-testid="widget-extension-top-level-summary">
          <span v-if="summaryError">{{ summaryError }}</span>
          <slot v-else name="summary">{{ isLoading ? loadingText : summary }}</slot>
        </div>
        <div class="gl-display-flex">
          <help-popover
            v-if="helpPopover"
            icon="information-o"
            :options="helpPopover.options"
            :class="{ 'gl-mr-3': hasActionButtons }"
          >
            <template v-if="helpPopover.content">
              <p
                v-if="helpPopover.content.text"
                v-safe-html="helpPopover.content.text"
                class="gl-mb-0"
              ></p>
              <gl-link
                v-if="helpPopover.content.learnMorePath"
                :href="helpPopover.content.learnMorePath"
                target="_blank"
                class="gl-font-sm"
                >{{ $options.i18n.learnMore }}</gl-link
              >
            </template>
          </help-popover>
          <slot name="action-buttons">
            <action-buttons
              v-if="actionButtons.length > 0"
              :widget="widgetName"
              :tertiary-buttons="actionButtons"
              @clickedAction="onActionClick"
            />
          </slot>
        </div>
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
            data-qa-selector="expand_report_button"
            @click="toggleCollapsed"
          />
        </div>
      </div>
    </div>
    <div
      v-if="!isCollapsed || contentError"
      class="gl-relative gl-bg-gray-10"
      data-testid="widget-extension-collapsed-section"
    >
      <div v-if="isLoadingExpandedContent" class="report-block-container gl-text-center">
        <gl-loading-icon size="sm" inline /> {{ loadingText }}
      </div>
      <div v-else class="gl-pl-5 gl-display-flex" :class="{ 'gl-pr-5': $scopedSlots.content }">
        <content-row
          v-if="contentError"
          :level="2"
          :status-icon-name="$options.failedStatusIcon"
          :widget-name="widgetName"
        >
          <template #body>
            {{ contentError }}
          </template>
        </content-row>
        <div v-else class="gl-w-full">
          <slot name="content">
            <dynamic-scroller
              v-if="content"
              :items="content"
              :min-item-size="32"
              :style="{ maxHeight: '170px' }"
              data-testid="dynamic-content-scroller"
              class="gl-pr-5"
            >
              <template #default="{ item, index, active }">
                <dynamic-scroller-item :item="item" :active="active">
                  <dynamic-content
                    :key="item.id || index"
                    :data="item"
                    :widget-name="widgetName"
                    :level="2"
                  />
                </dynamic-scroller-item>
              </template>
            </dynamic-scroller>
          </slot>
        </div>
      </div>
    </div>
  </section>
</template>
