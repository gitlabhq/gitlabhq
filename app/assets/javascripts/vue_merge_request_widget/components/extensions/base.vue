<script>
import { GlButton, GlLoadingIcon, GlTooltipDirective, GlIntersectionObserver } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import { sprintf, s__, __ } from '~/locale';
import Poll from '~/lib/utils/poll';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { EXTENSION_ICON_CLASS, EXTENSION_ICONS } from '../../constants';
import Actions from '../action_buttons.vue';
import StateContainer from '../state_container.vue';
import StatusIcon from './status_icon.vue';
import ChildContent from './child_content.vue';
import { createTelemetryHub } from './telemetry';
import { generateText } from './utils';

export const LOADING_STATES = {
  collapsedLoading: 'collapsedLoading',
  collapsedError: 'collapsedError',
  expandedLoading: 'expandedLoading',
  expandedError: 'expandedError',
};

export default {
  telemetry: true,
  components: {
    GlButton,
    GlLoadingIcon,
    GlIntersectionObserver,
    StatusIcon,
    Actions,
    ChildContent,
    DynamicScroller,
    DynamicScrollerItem,
    StateContainer,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      loadingState: LOADING_STATES.collapsedLoading,
      collapsedData: {},
      fullData: [],
      isCollapsed: true,
      showFade: false,
      modalData: undefined,
      modalName: undefined,
      telemetry: null,
    };
  },
  computed: {
    widgetLabel() {
      return this.$options.i18n?.label || this.$options.name;
    },
    widgetLoadingText() {
      return this.$options.i18n?.loading || __('Loading...');
    },
    widgetErrorText() {
      return this.$options.i18n?.error || __('Failed to load');
    },
    isLoadingSummary() {
      return this.loadingState === LOADING_STATES.collapsedLoading;
    },
    isLoadingExpanded() {
      return this.loadingState === LOADING_STATES.expandedLoading;
    },
    isCollapsible() {
      if (!this.isLoadingSummary && this.loadingState !== LOADING_STATES.collapsedError) {
        if (this.shouldCollapse) {
          return this.shouldCollapse(this.collapsedData);
        }

        return true;
      }

      return false;
    },
    hasFullData() {
      return this.fullData.length > 0;
    },
    hasFetchError() {
      return (
        this.loadingState === LOADING_STATES.collapsedError ||
        this.loadingState === LOADING_STATES.expandedError
      );
    },
    collapseButtonLabel() {
      return sprintf(
        this.isCollapsed
          ? s__('mrWidget|Show %{widget} details')
          : s__('mrWidget|Hide %{widget} details'),
        { widget: this.widgetLabel },
      );
    },
    statusIconName() {
      if (this.hasFetchError) return EXTENSION_ICONS.failed;
      if (this.isLoadingSummary) return null;

      return this.statusIcon(this.collapsedData);
    },
    tertiaryActionsButtons() {
      return this.tertiaryButtons ? this.tertiaryButtons() : undefined;
    },
    hydratedSummary() {
      const structuredOutput = this.summary(this.collapsedData);
      const summary = {
        subject: generateText(
          typeof structuredOutput === 'string' ? structuredOutput : structuredOutput.subject,
        ),
      };

      if (structuredOutput.meta) {
        summary.meta = generateText(structuredOutput.meta);
      }

      return summary;
    },
    modalId() {
      return this.modalName || `modal${this.$options.name}`;
    },
  },
  watch: {
    isCollapsed(newVal) {
      if (!newVal) {
        this.loadAllData();
      } else {
        this.loadingState = null;
      }
    },
  },
  created() {
    if (this.$options.telemetry) {
      this.telemetry = createTelemetryHub(this.$options.name);
    }
  },
  mounted() {
    this.loadCollapsedData();

    this.telemetry?.viewed();
  },
  methods: {
    toggleCollapsed(e) {
      if (this.isCollapsible && !e?.target?.closest('.btn:not(.btn-icon),a')) {
        if (this.isCollapsed) {
          this.telemetry?.expanded({ type: this.statusIconName });
        }

        this.isCollapsed = !this.isCollapsed;
      }
    },
    initExtensionMultiPolling() {
      const allData = [];
      const requests = this.fetchMultiData();

      requests.forEach((request) => {
        const poll = new Poll({
          resource: {
            fetchData: () => request(this),
          },
          method: 'fetchData',
          successCallback: (response) => {
            this.headerCheck(response, (data) => allData.push(data));

            if (allData.length === requests.length) {
              this.setCollapsedData(allData);
            }
          },
          errorCallback: (e) => {
            this.setCollapsedError(e);
          },
        });

        poll.makeRequest();
      });
    },
    initExtensionPolling() {
      const poll = new Poll({
        resource: {
          fetchData: () => this.fetchCollapsedData(this),
        },
        method: 'fetchData',
        successCallback: (response) => {
          this.headerCheck(response, (data) => this.setCollapsedData(data));
        },
        errorCallback: (e) => {
          this.setCollapsedError(e);
        },
      });

      poll.makeRequest();
    },
    initExtensionFullDataPolling() {
      const poll = new Poll({
        resource: {
          fetchData: () => this.fetchFullData(this),
        },
        method: 'fetchData',
        successCallback: (response) => {
          this.headerCheck(response, (data) => {
            this.setFullData(data);
          });
        },
        errorCallback: (e) => {
          this.setExpandedError(e);
        },
      });

      poll.makeRequest();
    },
    headerCheck(response, callback) {
      const headers = normalizeHeaders(response.headers);

      if (!headers['POLL-INTERVAL']) {
        callback(response.data);
      }
    },
    loadCollapsedData() {
      this.loadingState = LOADING_STATES.collapsedLoading;

      if (this.$options.enablePolling) {
        if (this.fetchMultiData) {
          this.initExtensionMultiPolling();
        } else {
          this.initExtensionPolling();
        }
      } else {
        this.fetchCollapsedData(this)
          .then((data) => {
            this.setCollapsedData(data);
          })
          .catch((e) => {
            this.setCollapsedError(e);
          });
      }
    },
    setFullData(data) {
      this.loadingState = null;
      this.fullData = data.map((x, i) => ({ id: i, ...x }));
    },
    setCollapsedData(data) {
      this.collapsedData = data;
      this.loadingState = null;
    },
    setCollapsedError(e) {
      this.loadingState = LOADING_STATES.collapsedError;

      Sentry.captureException(e);
    },
    setExpandedError(e) {
      this.loadingState = LOADING_STATES.expandedError;
      Sentry.captureException(e);
    },
    loadAllData() {
      if (this.hasFullData) return;

      this.loadingState = LOADING_STATES.expandedLoading;

      if (this.$options.enableExpandedPolling) {
        this.initExtensionFullDataPolling();
      } else {
        this.fetchFullData(this)
          .then((data) => {
            this.setFullData(data);
          })
          .catch((e) => {
            this.setExpandedError(e);
          });
      }
    },
    appear(index) {
      if (index === this.fullData.length - 1) {
        this.showFade = false;
      }
    },
    disappear(index) {
      if (index === this.fullData.length - 1) {
        this.showFade = true;
      }
    },
    onRowMouseDown() {
      this.down = Number(new Date());
    },
    onRowMouseUp(e) {
      const up = Number(new Date());

      // To allow for text to be selected we check if the the user is clicking
      // or selecting, if they are selecting the time difference should be
      // more than 200ms
      if (up - this.down < 200 && !e?.target?.closest('.btn-icon')) {
        this.toggleCollapsed(e);
      }
    },
    onClickedAction(action) {
      if (action.trackFullReportClicked) {
        this.telemetry?.fullReportClicked();
      }
    },
    generateText,
  },
  EXTENSION_ICON_CLASS,
};
</script>

<template>
  <section
    class="media-section"
    data-testid="widget-extension"
    data-qa-selector="mr_widget_extension"
  >
    <state-container
      :status="statusIconName"
      :is-loading="isLoadingSummary"
      :class="{ 'gl-cursor-pointer': isCollapsible }"
      class="gl-pl-5 gl-pr-4 gl-py-4"
      @mousedown="onRowMouseDown"
      @mouseup="onRowMouseUp"
    >
      <div
        :class="{ 'gl-h-full': isLoadingSummary }"
        class="media-body gl-display-flex gl-flex-direction-row! gl-w-full"
        data-testid="widget-extension-top-level"
      >
        <div
          class="gl-flex-grow-1 gl-display-flex gl-align-items-center gl-flex-wrap"
          data-testid="widget-extension-top-level-summary"
        >
          <div v-if="isLoadingSummary" class="gl-w-full gl-line-height-normal">
            {{ widgetLoadingText }}
          </div>
          <div v-else-if="hasFetchError" class="gl-w-full gl-line-height-normal">
            {{ widgetErrorText }}
          </div>
          <template v-else>
            <div
              v-safe-html="hydratedSummary.subject"
              class="gl-w-full gl-line-height-normal"
            ></div>
            <template v-if="hydratedSummary.meta">
              <div
                v-safe-html="hydratedSummary.meta"
                class="gl-w-full gl-font-sm gl-line-height-normal"
              ></div>
            </template>
          </template>
        </div>
        <actions
          :widget="$options.label || $options.name"
          :tertiary-buttons="tertiaryActionsButtons"
          @clickedAction="onClickedAction"
        />
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
            data-qa-selector="toggle_button"
            size="small"
            @click="toggleCollapsed"
          />
        </div>
      </div>
    </state-container>
    <div
      v-if="!isCollapsed"
      class="mr-widget-grouped-section gl-relative"
      data-testid="widget-extension-collapsed-section"
    >
      <div v-if="isLoadingExpanded" class="report-block-container">
        <gl-loading-icon size="sm" inline /> {{ __('Loading...') }}
      </div>
      <dynamic-scroller
        v-else-if="hasFullData"
        :items="fullData"
        :min-item-size="32"
        class="report-block-container gl-p-0"
      >
        <template #default="{ item, index, active }">
          <dynamic-scroller-item :item="item" :active="active" :class="{ active }">
            <div
              :class="{
                'gl-border-b-solid gl-border-b-1 gl-border-gray-100': index !== fullData.length - 1,
              }"
              class="gl-py-3 gl-pl-9"
              data-testid="extension-list-item"
            >
              <gl-intersection-observer
                :options="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
                  rootMargin: '100px',
                  thresholds: 0.1,
                } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
                class="gl-w-full"
                @appear="appear(index)"
                @disappear="disappear(index)"
              >
                <child-content
                  :data="item"
                  :widget-label="widgetLabel"
                  :modal-id="modalId"
                  :level="2"
                  @clickedAction="onClickedAction"
                />
              </gl-intersection-observer>
            </div>
          </dynamic-scroller-item>
        </template>
      </dynamic-scroller>
      <div
        :class="{ show: showFade }"
        class="fade mr-extenson-scrim gl-absolute gl-left-0 gl-bottom-0 gl-w-full gl-h-7 gl-pointer-events-none"
      ></div>
    </div>
    <div v-if="$options.modalComponent && modalData">
      <component :is="$options.modalComponent" :modal-id="modalId" v-bind="modalData" />
    </div>
  </section>
</template>
