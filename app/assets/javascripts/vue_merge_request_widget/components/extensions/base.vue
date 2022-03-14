<script>
import {
  GlButton,
  GlLoadingIcon,
  GlSafeHtmlDirective,
  GlTooltipDirective,
  GlIntersectionObserver,
} from '@gitlab/ui';
import { once } from 'lodash';
import * as Sentry from '@sentry/browser';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import api from '~/api';
import { sprintf, s__, __ } from '~/locale';
import Poll from '~/lib/utils/poll';
import { EXTENSION_ICON_CLASS, EXTENSION_ICONS } from '../../constants';
import StatusIcon from './status_icon.vue';
import Actions from './actions.vue';
import ChildContent from './child_content.vue';
import { generateText } from './utils';

export const LOADING_STATES = {
  collapsedLoading: 'collapsedLoading',
  collapsedError: 'collapsedError',
  expandedLoading: 'expandedLoading',
  expandedError: 'expandedError',
};

export default {
  components: {
    GlButton,
    GlLoadingIcon,
    GlIntersectionObserver,
    StatusIcon,
    Actions,
    ChildContent,
    DynamicScroller,
    DynamicScrollerItem,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      loadingState: LOADING_STATES.collapsedLoading,
      collapsedData: {},
      fullData: [],
      isCollapsed: true,
      showFade: false,
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
      return !this.isLoadingSummary && this.loadingState !== LOADING_STATES.collapsedError;
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
  mounted() {
    this.loadCollapsedData();
  },
  methods: {
    triggerRedisTracking: once(function triggerRedisTracking() {
      if (this.$options.expandEvent) {
        api.trackRedisHllUserEvent(this.$options.expandEvent);
      }
    }),
    toggleCollapsed(e) {
      if (!e?.target?.closest('.btn:not(.btn-icon),a')) {
        this.isCollapsed = !this.isCollapsed;

        this.triggerRedisTracking();
      }
    },
    initExtensionPolling() {
      const poll = new Poll({
        resource: {
          fetchData: () => this.fetchCollapsedData(this.$props),
        },
        method: 'fetchData',
        successCallback: ({ data }) => {
          if (Object.keys(data).length > 0) {
            poll.stop();
            this.setCollapsedData(data);
          }
        },
        errorCallback: (e) => {
          poll.stop();

          this.setCollapsedError(e);
        },
      });

      poll.makeRequest();
    },
    loadCollapsedData() {
      this.loadingState = LOADING_STATES.collapsedLoading;

      if (this.$options.enablePolling) {
        this.initExtensionPolling();
      } else {
        this.fetchCollapsedData(this.$props)
          .then((data) => {
            this.setCollapsedData(data);
          })
          .catch((e) => {
            this.setCollapsedError(e);
          });
      }
    },
    setCollapsedData(data) {
      this.collapsedData = data;
      this.loadingState = null;
    },
    setCollapsedError(e) {
      this.loadingState = LOADING_STATES.collapsedError;

      Sentry.captureException(e);
    },
    loadAllData() {
      if (this.hasFullData) return;

      this.loadingState = LOADING_STATES.expandedLoading;

      this.fetchFullData(this.$props)
        .then((data) => {
          this.loadingState = null;
          this.fullData = data.map((x, i) => ({ id: i, ...x }));
        })
        .catch((e) => {
          this.loadingState = LOADING_STATES.expandedError;

          Sentry.captureException(e);
        });
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
      if (up - this.down < 200) {
        this.toggleCollapsed(e);
      }
    },
    generateText,
  },
  EXTENSION_ICON_CLASS,
};
</script>

<template>
  <section class="media-section" data-testid="widget-extension">
    <div class="media gl-p-5 gl-cursor-pointer" @mousedown="onRowMouseDown" @mouseup="onRowMouseUp">
      <status-icon
        :name="$options.label || $options.name"
        :is-loading="isLoadingSummary"
        :icon-name="statusIconName"
      />
      <div
        class="media-body gl-display-flex gl-flex-direction-row! gl-align-self-center"
        data-testid="widget-extension-top-level"
      >
        <div class="gl-flex-grow-1">
          <template v-if="isLoadingSummary">{{ widgetLoadingText }}</template>
          <template v-else-if="hasFetchError">{{ widgetErrorText }}</template>
          <div v-else>
            <span v-safe-html="hydratedSummary.subject"></span>
            <template v-if="hydratedSummary.meta">
              <br />
              <span v-safe-html="hydratedSummary.meta" class="gl-font-sm"></span>
            </template>
          </div>
        </div>
        <actions
          :widget="$options.label || $options.name"
          :tertiary-buttons="tertiaryActionsButtons"
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
            size="small"
            @click.self="toggleCollapsed"
          />
        </div>
      </div>
    </div>
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
        class="report-block-container gl-px-5 gl-py-0"
      >
        <template #default="{ item, index, active }">
          <dynamic-scroller-item :item="item" :active="active" :class="{ active }">
            <div
              :class="{
                'gl-border-b-solid gl-border-b-1 gl-border-gray-100': index !== fullData.length - 1,
              }"
              class="gl-py-3 gl-pl-7"
              data-testid="extension-list-item"
            >
              <gl-intersection-observer
                :options="{ rootMargin: '100px', thresholds: 0.1 }"
                class="gl-w-full"
                @appear="appear(index)"
                @disappear="disappear(index)"
              >
                <child-content :data="item" :widget-label="widgetLabel" :level="2" />
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
  </section>
</template>
