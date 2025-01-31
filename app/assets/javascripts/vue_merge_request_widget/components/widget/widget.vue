<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlLink, GlTooltipDirective, GlLoadingIcon } from '@gitlab/ui';
import { kebabCase } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { logError } from '~/lib/logger';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { sprintf, __ } from '~/locale';
import Poll from '~/lib/utils/poll';
import { joinPaths } from '~/lib/utils/url_utility';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import { EXTENSION_ICONS } from '../../constants';
import { generateText } from './utils';
import { createTelemetryHub } from './telemetry';
import ContentRow from './widget_content_row.vue';
import DynamicContent from './dynamic_content.vue';
import StatusIcon from './status_icon.vue';
import ActionButtons from './action_buttons.vue';

const WIDGET_PREFIX = 'Widget';
const MISSING_RESPONSE_HEADERS =
  'MR Widget: response object should contain status and headers object. Make sure to include that in your `fetchCollapsedData` and `fetchExpandedData` functions.';

const LOADING_STATE_COLLAPSED = 'collapsed';
const LOADING_STATE_EXPANDED = 'expanded';
const LOADING_STATE_STATUS_ICON = 'status_icon';

export default {
  MISSING_RESPONSE_HEADERS,
  LOADING_STATE_COLLAPSED,
  LOADING_STATE_EXPANDED,
  LOADING_STATE_STATUS_ICON,

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
  mixins: [glFeatureFlagsMixin()],
  inject: { reportsTabContent: { default: false } },
  props: {
    loadingText: {
      type: String,
      required: false,
      default: __('Loading'),
    },
    // Use this property when you need to control the loading state from the
    // parent component.
    loadingState: {
      type: String,
      required: false,
      default: undefined,
      validator: (s) => {
        if (!s) {
          return true;
        }

        return [
          LOADING_STATE_EXPANDED,
          LOADING_STATE_COLLAPSED,
          LOADING_STATE_STATUS_ICON,
        ].includes(s);
      },
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
      type: Object,
      required: false,
      default: undefined,
      validator: (s) => {
        return Boolean(s.title);
      },
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
      // see https://docs.gitlab.com/ee/development/fe_guide/merge_request_widgets.html#add-new-widgets
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
      isCollapsed: !this.reportsTabContent,
      isLoadingCollapsedContent: true,
      isLoadingExpandedContent: false,
      summaryError: null,
      contentError: null,
      telemetryHub: null,
    };
  },
  computed: {
    isSummaryLoading() {
      return this.isLoadingCollapsedContent || this.loadingState === LOADING_STATE_COLLAPSED;
    },
    shouldShowLoadingIcon() {
      return this.isSummaryLoading || this.loadingState === LOADING_STATE_STATUS_ICON;
    },
    generatedSummary() {
      return generateText(this.summary?.title || '');
    },
    generatedSubSummary() {
      return generateText(this.summary?.subtitle || '');
    },
    collapseButtonLabel() {
      return sprintf(this.isCollapsed ? __('Show details') : __('Hide details'));
    },
    summaryStatusIcon() {
      return this.summaryError ? this.$options.failedStatusIcon : this.statusIconName;
    },
    hasActionButtons() {
      return this.actionButtons.length > 0 || Boolean(this.$scopedSlots['action-buttons']);
    },
    contentWithKeyField() {
      return this.content?.map((item, index) => ({ ...item, id: item.id || index }));
    },
    reportsTabActionButtons() {
      return [
        {
          text: __('View report'),
          href: joinPaths(
            window.gl?.mrWidgetData?.reportsTabPath || '',
            kebabCase(this.widgetName.replace(WIDGET_PREFIX, '')),
          ),
          onClick(action, e) {
            e.preventDefault();

            window.history.replaceState(null, null, action.href);
            window.mrTabs.tabShown('reports');
          },
        },
      ];
    },
  },
  watch: {
    hasError: {
      handler(newValue) {
        this.summaryError = newValue ? this.errorText : null;
      },
      immediate: true,
    },
    isLoadingCollapsedContent(newValue) {
      this.$emit('is-loading', newValue);
    },
  },
  created() {
    if (this.telemetry) {
      this.telemetryHub = createTelemetryHub(this.widgetName);
    }
  },
  async mounted() {
    this.isLoadingCollapsedContent = true;
    this.telemetryHub?.viewed();

    try {
      if (this.fetchCollapsedData) {
        await this.fetch(this.fetchCollapsedData);
      }
    } catch {
      this.summaryError = this.errorText;
    }

    if (this.reportsTabContent) {
      this.fetchExpandedContent();
    }

    this.isLoadingCollapsedContent = false;
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
        await this.fetch(this.fetchExpandedData);
      } catch {
        this.contentError = this.errorText;

        // Reset these values so that we allow refetching
        this.isExpandedForTheFirstTime = true;
        this.isCollapsed = true;
      }

      this.isLoadingExpandedContent = false;
    },
    fetch(handler) {
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

      return Promise.all(promises);
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
    <div
      v-if="!reportsTabContent"
      :class="{
        'gl-pl-9': glFeatures.mrReportsTab,
        'gl-flex gl-px-5 gl-py-4 gl-pr-4': !reportsTabContent,
      }"
    >
      <status-icon
        :level="glFeatures.mrReportsTab ? 2 : 1"
        :name="widgetName"
        :is-loading="shouldShowLoadingIcon"
        :icon-name="summaryStatusIcon"
      />
      <div
        class="media-body gl-flex !gl-flex-row gl-self-center"
        data-testid="widget-extension-top-level"
      >
        <div class="gl-grow" data-testid="widget-extension-top-level-summary">
          <span v-if="summaryError">{{ summaryError }}</span>
          <slot v-else name="summary"
            ><div v-safe-html="isSummaryLoading ? loadingText : generatedSummary"></div>
            <div
              v-if="!isSummaryLoading && generatedSubSummary"
              v-safe-html="generatedSubSummary"
              class="gl-text-sm gl-text-subtle"
            ></div
          ></slot>
        </div>
        <div class="gl-flex">
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
                class="gl-text-sm"
                >{{ $options.i18n.learnMore }}</gl-link
              >
            </template>
          </help-popover>
          <div v-if="glFeatures.mrReportsTab">
            <action-buttons :tertiary-buttons="reportsTabActionButtons" />
          </div>
          <slot v-else name="action-buttons">
            <action-buttons
              v-if="actionButtons.length > 0"
              :tertiary-buttons="actionButtons"
              @clickedAction="onActionClick"
            />
          </slot>
        </div>
        <div
          v-if="!glFeatures.mrReportsTab && isCollapsible && !isSummaryLoading"
          class="gl-border-l gl-ml-3 gl-h-6 gl-pl-3"
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
      v-if="!isCollapsed || contentError"
      :class="{ 'gl-border-t gl-relative gl-border-t-section gl-bg-subtle': !reportsTabContent }"
      data-testid="widget-extension-collapsed-section"
    >
      <div
        v-if="isLoadingExpandedContent"
        class="gl-text-center"
        :class="{ 'report-block-container': !reportsTabContent, 'gl-py-5': reportsTabContent }"
      >
        <gl-loading-icon size="sm" inline /> {{ loadingText }}
      </div>
      <div v-else class="gl-flex gl-pl-5" :class="{ 'gl-pr-5': $scopedSlots.content }">
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
              v-if="contentWithKeyField"
              :items="contentWithKeyField"
              :min-item-size="32"
              :style="{ maxHeight: reportsTabContent ? null : '170px' }"
              :page-mode="glFeatures.mrReportsTab && reportsTabContent"
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
                    :row-index="index"
                    data-testid="extension-list-item"
                    @clickedAction="onActionClick"
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
