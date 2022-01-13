<script>
import { GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { JOB_SIDEBAR } from '../../constants';
import CommitBlock from '../../components/commit_block.vue';

export default {
  styles: {
    width: '290px',
  },
  name: 'BridgeSidebar',
  i18n: {
    ...JOB_SIDEBAR,
    retryButton: __('Retry'),
    retryTriggerJob: __('Retry the trigger job'),
    retryDownstreamPipeline: __('Retry the downstream pipeline'),
  },
  sectionClass: ['gl-border-t-solid', 'gl-border-t-1', 'gl-border-t-gray-100', 'gl-py-5'],
  components: {
    CommitBlock,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    TooltipOnTruncate,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    bridgeJob: {
      type: Object,
      required: true,
    },
    commit: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      topPosition: 0,
    };
  },
  computed: {
    rootStyle() {
      return { ...this.$options.styles, top: `${this.topPosition}px` };
    },
  },
  mounted() {
    this.setTopPosition();
  },
  methods: {
    onSidebarButtonClick() {
      this.$emit('toggleSidebar');
    },
    setTopPosition() {
      const navbarEl = document.querySelector('.js-navbar');

      if (navbarEl) {
        this.topPosition = navbarEl.getBoundingClientRect().bottom;
      }
    },
  },
};
</script>
<template>
  <aside
    class="gl-fixed gl-right-0 gl-px-5 gl-bg-gray-10 gl-h-full gl-border-l-solid gl-border-1 gl-border-gray-100 gl-z-index-200 gl-overflow-hidden"
    :style="rootStyle"
  >
    <div class="gl-py-5 gl-display-flex gl-align-items-center">
      <tooltip-on-truncate :title="bridgeJob.name" truncate-target="child"
        ><h4 class="gl-mb-0 gl-mr-2 gl-text-truncate">
          {{ bridgeJob.name }}
        </h4>
      </tooltip-on-truncate>
      <!-- TODO: implement retry actions -->
      <div
        v-if="glFeatures.triggerJobRetryAction"
        class="gl-flex-grow-1 gl-flex-shrink-0 gl-text-right"
      >
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
        @click="onSidebarButtonClick"
      />
    </div>
    <commit-block :commit="commit" :class="$options.sectionClass" />
    <!-- TODO: show stage dropdown, jobs list -->
  </aside>
</template>
