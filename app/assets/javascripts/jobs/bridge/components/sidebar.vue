<script>
import { GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { __ } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { JOB_SIDEBAR } from '../../constants';
import { SIDEBAR_COLLAPSE_BREAKPOINTS } from './constants';

export default {
  styles: {
    top: '75px',
    width: '290px',
  },
  name: 'BridgeSidebar',
  i18n: {
    ...JOB_SIDEBAR,
    retryButton: __('Retry'),
    retryTriggerJob: __('Retry the trigger job'),
    retryDownstreamPipeline: __('Retry the downstream pipeline'),
  },
  borderTopClass: ['gl-border-t-solid', 'gl-border-t-1', 'gl-border-t-gray-100'],
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    TooltipOnTruncate,
  },
  inject: {
    buildName: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      isSidebarExpanded: true,
    };
  },
  created() {
    window.addEventListener('resize', this.onResize);
  },
  mounted() {
    this.onResize();
  },
  methods: {
    toggleSidebar() {
      this.isSidebarExpanded = !this.isSidebarExpanded;
    },
    onResize() {
      const breakpoint = bp.getBreakpointSize();
      if (SIDEBAR_COLLAPSE_BREAKPOINTS.includes(breakpoint)) {
        this.isSidebarExpanded = false;
      } else if (!this.isSidebarExpanded) {
        this.isSidebarExpanded = true;
      }
    },
  },
};
</script>
<template>
  <aside
    class="gl-fixed gl-right-0 gl-px-5 gl-bg-gray-10 gl-h-full gl-border-l-solid gl-border-1 gl-border-gray-100 gl-z-index-200 gl-overflow-hidden"
    :style="this.$options.styles"
    :class="{
      'gl-display-none': !isSidebarExpanded,
    }"
  >
    <div class="gl-py-5 gl-display-flex gl-align-items-center">
      <tooltip-on-truncate :title="buildName" truncate-target="child"
        ><h4 class="gl-mb-0 gl-mr-2 gl-text-truncate">
          {{ buildName }}
        </h4>
      </tooltip-on-truncate>
      <!-- TODO: implement retry actions -->
      <div class="gl-flex-grow-1 gl-flex-shrink-0 gl-text-right">
        <gl-dropdown
          :text="$options.i18n.retryButton"
          category="primary"
          variant="confirm"
          right
          size="medium"
        >
          <gl-dropdown-item>{{ $options.i18n.retryTriggerJob }}</gl-dropdown-item>
          <gl-dropdown-item>{{ $options.i18n.retryDownstreamPipeline }}</gl-dropdown-item>
        </gl-dropdown>
      </div>
      <gl-button
        :aria-label="$options.i18n.toggleSidebar"
        data-testid="sidebar-expansion-toggle"
        category="tertiary"
        class="gl-md-display-none gl-ml-2"
        icon="chevron-double-lg-right"
        @click="toggleSidebar"
      />
    </div>
    <!-- TODO: get job details and show commit block, stage dropdown, jobs list -->
  </aside>
</template>
