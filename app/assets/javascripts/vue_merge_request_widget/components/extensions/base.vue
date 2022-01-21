<script>
import {
  GlButton,
  GlLoadingIcon,
  GlLink,
  GlBadge,
  GlSafeHtmlDirective,
  GlTooltipDirective,
  GlIntersectionObserver,
} from '@gitlab/ui';
import { once } from 'lodash';
import * as Sentry from '@sentry/browser';
import api from '~/api';
import { sprintf, s__, __ } from '~/locale';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';
import Poll from '~/lib/utils/poll';
import { EXTENSION_ICON_CLASS, EXTENSION_ICONS } from '../../constants';
import StatusIcon from './status_icon.vue';
import Actions from './actions.vue';
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
    GlLink,
    GlBadge,
    GlIntersectionObserver,
    SmartVirtualList,
    StatusIcon,
    Actions,
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
      if (this.hasFetchError) return EXTENSION_ICONS.error;
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
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;

      this.triggerRedisTracking();
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
          this.fullData = data;
        })
        .catch((e) => {
          this.loadingState = LOADING_STATES.expandedError;

          Sentry.captureException(e);
        });
    },
    isArray(arr) {
      return Array.isArray(arr);
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
    generateText,
  },
  EXTENSION_ICON_CLASS,
};
</script>

<template>
  <section class="media-section" data-testid="widget-extension">
    <div class="media gl-p-5">
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
      <div v-if="isLoadingExpanded" class="report-block-container">
        <gl-loading-icon size="sm" inline /> {{ __('Loading...') }}
      </div>
      <smart-virtual-list
        v-else-if="hasFullData"
        :length="fullData.length"
        :remain="20"
        :size="32"
        wtag="ul"
        wclass="report-block-list"
        class="report-block-container gl-px-5 gl-py-0"
      >
        <li
          v-for="(data, index) in fullData"
          :key="data.id"
          :class="{
            'gl-border-b-solid gl-border-b-1 gl-border-gray-100': index !== fullData.length - 1,
          }"
          class="gl-py-3 gl-pl-7"
          data-testid="extension-list-item"
        >
          <div class="gl-w-full">
            <div v-if="data.header" class="gl-mb-2">
              <template v-if="isArray(data.header)">
                <component
                  :is="headerI === 0 ? 'strong' : 'span'"
                  v-for="(header, headerI) in data.header"
                  :key="headerI"
                  v-safe-html="generateText(header)"
                  class="gl-display-block"
                />
              </template>
              <strong v-else v-safe-html="generateText(data.header)"></strong>
            </div>
            <div class="gl-display-flex">
              <status-icon
                v-if="data.icon"
                :icon-name="data.icon.name"
                :size="12"
                class="gl-pl-0"
              />
              <gl-intersection-observer
                :options="{ rootMargin: '100px', thresholds: 0.1 }"
                class="gl-w-full"
                @appear="appear(index)"
                @disappear="disappear(index)"
              >
                <div class="gl-flex-wrap gl-display-flex gl-w-full">
                  <div class="gl-mr-4 gl-display-flex gl-align-items-center">
                    <p v-safe-html="generateText(data.text)" class="gl-m-0"></p>
                  </div>
                  <div v-if="data.link">
                    <gl-link :href="data.link.href">{{ data.link.text }}</gl-link>
                  </div>
                  <div v-if="data.supportingText">
                    <p v-safe-html="generateText(data.supportingText)" class="gl-m-0"></p>
                  </div>
                  <gl-badge v-if="data.badge" :variant="data.badge.variant || 'info'">
                    {{ data.badge.text }}
                  </gl-badge>

                  <actions
                    :widget="$options.label || $options.name"
                    :tertiary-buttons="data.actions"
                    class="gl-ml-auto"
                  />
                </div>
                <p
                  v-if="data.subtext"
                  v-safe-html="generateText(data.subtext)"
                  class="gl-m-0 gl-font-sm"
                ></p>
              </gl-intersection-observer>
            </div>
          </div>
        </li>
      </smart-virtual-list>
      <div
        :class="{ show: showFade }"
        class="fade mr-extenson-scrim gl-absolute gl-left-0 gl-bottom-0 gl-w-full gl-h-7 gl-pointer-events-none"
      ></div>
    </div>
  </section>
</template>
