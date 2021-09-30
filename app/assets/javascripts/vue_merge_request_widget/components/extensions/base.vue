<script>
import { GlButton, GlLoadingIcon, GlLink, GlBadge, GlSafeHtmlDirective } from '@gitlab/ui';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';
import { EXTENSION_ICON_CLASS } from '../../constants';
import StatusIcon from './status_icon.vue';

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
    SmartVirtualList,
    StatusIcon,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  data() {
    return {
      loadingState: LOADING_STATES.collapsedLoading,
      collapsedData: null,
      fullData: null,
      isCollapsed: true,
    };
  },
  computed: {
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
    statusIconName() {
      if (this.isLoadingSummary) return null;

      return this.statusIcon(this.collapsedData);
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
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
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
  },
  EXTENSION_ICON_CLASS,
};
</script>

<template>
  <section class="media-section mr-widget-border-top" data-testid="widget-extension">
    <div class="media gl-p-5">
      <status-icon
        :name="$options.name"
        :is-loading="isLoadingSummary"
        :icon-name="statusIconName"
      />
      <div class="media-body d-flex flex-align-self-center align-items-center">
        <div class="code-text">
          <template v-if="isLoadingSummary">
            {{ __('Loading...') }}
          </template>
          <div v-else v-safe-html="summary(collapsedData)"></div>
        </div>
        <gl-button
          v-if="isCollapsible"
          size="small"
          class="float-right align-self-center"
          data-testid="toggle-button"
          @click="toggleCollapsed"
        >
          {{ isCollapsed ? __('Expand') : __('Collapse') }}
        </gl-button>
      </div>
    </div>
    <div
      v-if="!isCollapsed"
      class="mr-widget-grouped-section"
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
        class="report-block-container"
      >
        <li v-for="data in fullData" :key="data.id" class="d-flex align-items-center">
          <status-icon v-if="data.icon" :icon-name="data.icon.name" :size="12" />
          <div
            class="gl-mt-2 gl-mb-2 align-content-around align-items-start flex-wrap align-self-center d-flex"
          >
            <div v-safe-html="data.text" class="gl-mr-4"></div>
            <div v-if="data.link">
              <gl-link :href="data.link.href">{{ data.link.text }}</gl-link>
            </div>
            <gl-badge v-if="data.badge" :variant="data.badge.variant || 'info'">
              {{ data.badge.text }}
            </gl-badge>
          </div>
        </li>
      </smart-virtual-list>
    </div>
  </section>
</template>
