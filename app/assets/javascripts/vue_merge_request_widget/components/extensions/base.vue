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
import api from '~/api';
import { sprintf, s__, __ } from '~/locale';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';
import { EXTENSION_ICON_CLASS } from '../../constants';
import StatusIcon from './status_icon.vue';
import Actions from './actions.vue';

export const LOADING_STATES = {
  collapsedLoading: 'collapsedLoading',
  collapsedError: 'collapsedError',
  expandedLoading: 'expandedLoading',
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
      collapsedData: null,
      fullData: null,
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
    isLoadingSummary() {
      return this.loadingState === LOADING_STATES.collapsedLoading;
    },
    isLoadingExpanded() {
      return this.loadingState === LOADING_STATES.expandedLoading;
    },
    isCollapsible() {
      if (this.isLoadingSummary) {
        return false;
      }

      return true;
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
      if (this.isLoadingSummary) return null;

      return this.statusIcon(this.collapsedData);
    },
    tertiaryActionsButtons() {
      return this.tertiaryButtons ? this.tertiaryButtons() : undefined;
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
    this.fetchCollapsedData(this.$props)
      .then((data) => {
        this.collapsedData = data;
        this.loadingState = null;
      })
      .catch((e) => {
        this.loadingState = LOADING_STATES.collapsedError;
        throw e;
      });
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
    loadAllData() {
      if (this.fullData) return;

      this.loadingState = LOADING_STATES.expandedLoading;

      this.fetchFullData(this.$props)
        .then((data) => {
          this.loadingState = null;
          this.fullData = data;
        })
        .catch((e) => {
          this.loadingState = null;
          throw e;
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
        class="media-body gl-display-flex gl-flex-direction-row!"
        data-testid="widget-extension-top-level"
      >
        <div class="gl-flex-grow-1">
          <template v-if="isLoadingSummary">{{ widgetLoadingText }}</template>
          <div v-else v-safe-html="summary(collapsedData)"></div>
        </div>
        <actions
          :widget="$options.label || $options.name"
          :tertiary-buttons="tertiaryActionsButtons"
        />
        <div class="gl-border-l-1 gl-border-l-solid gl-border-gray-100 gl-ml-3 gl-pl-3 gl-h-6">
          <gl-button
            v-if="isCollapsible"
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
        v-else-if="fullData"
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
          class="gl-display-flex gl-align-items-center gl-py-3 gl-pl-7"
          data-testid="extension-list-item"
        >
          <status-icon v-if="data.icon" :icon-name="data.icon.name" :size="12" class="gl-pl-0" />
          <gl-intersection-observer
            :options="{ rootMargin: '100px', thresholds: 0.1 }"
            class="gl-flex-wrap gl-display-flex gl-w-full"
            @appear="appear(index)"
            @disappear="disappear(index)"
          >
            <div
              v-safe-html="data.text"
              class="gl-mr-4 gl-display-flex gl-align-items-center"
            ></div>
            <div v-if="data.link">
              <gl-link :href="data.link.href">{{ data.link.text }}</gl-link>
            </div>
            <gl-badge v-if="data.badge" :variant="data.badge.variant || 'info'">
              {{ data.badge.text }}
            </gl-badge>
            <actions
              :widget="$options.label || $options.name"
              :tertiary-buttons="data.actions"
              class="gl-ml-auto"
            />
          </gl-intersection-observer>
        </li>
      </smart-virtual-list>
      <div
        :class="{ show: showFade }"
        class="fade mr-extenson-scrim gl-absolute gl-left-0 gl-bottom-0 gl-w-full gl-h-7"
      ></div>
    </div>
  </section>
</template>
