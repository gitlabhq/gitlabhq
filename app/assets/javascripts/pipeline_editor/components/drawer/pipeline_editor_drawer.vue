<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { DRAWER_EXPANDED_KEY } from '../../constants';
import FirstPipelineCard from './cards/first_pipeline_card.vue';
import GettingStartedCard from './cards/getting_started_card.vue';
import PipelineConfigReferenceCard from './cards/pipeline_config_reference_card.vue';
import VisualizeAndLintCard from './cards/visualize_and_lint_card.vue';

export default {
  width: {
    expanded: '482px',
    collapsed: '58px',
  },
  i18n: {
    toggleTxt: __('Collapse'),
  },
  localDrawerKey: DRAWER_EXPANDED_KEY,
  components: {
    FirstPipelineCard,
    GettingStartedCard,
    GlButton,
    GlIcon,
    LocalStorageSync,
    PipelineConfigReferenceCard,
    VisualizeAndLintCard,
  },
  data() {
    return {
      isExpanded: true,
      topPosition: 0,
    };
  },
  computed: {
    buttonIconName() {
      return this.isExpanded ? 'chevron-double-lg-right' : 'chevron-double-lg-left';
    },
    buttonClass() {
      return this.isExpanded ? 'gl-justify-content-end!' : '';
    },
    rootStyle() {
      const { expanded, collapsed } = this.$options.width;
      const top = this.topPosition;
      const style = { top: `${top}px` };

      return this.isExpanded ? { ...style, width: expanded } : { ...style, width: collapsed };
    },
  },
  mounted() {
    this.setTopPosition();
  },
  methods: {
    setTopPosition() {
      const navbarEl = document.querySelector('.js-navbar');

      if (navbarEl) {
        this.topPosition = navbarEl.getBoundingClientRect().bottom;
      }
    },
    toggleDrawer() {
      this.isExpanded = !this.isExpanded;
    },
  },
};
</script>
<template>
  <local-storage-sync v-model="isExpanded" :storage-key="$options.localDrawerKey" as-json>
    <aside
      aria-live="polite"
      class="gl-fixed gl-right-0 gl-bg-gray-10 gl-shadow-drawer gl-transition-medium gl-border-l-solid gl-border-1 gl-border-gray-100 gl-h-full gl-z-index-3 gl-overflow-y-auto"
      :style="rootStyle"
    >
      <gl-button
        category="tertiary"
        class="gl-w-full gl-h-9 gl-rounded-0! gl-border-none! gl-border-b-solid! gl-border-1! gl-border-gray-100 gl-text-decoration-none! gl-outline-0! gl-display-flex"
        :class="buttonClass"
        :title="__('Toggle sidebar')"
        @click="toggleDrawer"
      >
        <span v-if="isExpanded" class="gl-text-gray-500 gl-mr-3" data-testid="collapse-text">
          {{ __('Collapse') }}
        </span>
        <gl-icon data-testid="toggle-icon" :name="buttonIconName" />
      </gl-button>
      <div v-if="isExpanded" class="gl-h-full gl-p-5" data-testid="drawer-content">
        <getting-started-card class="gl-mb-4" />
        <first-pipeline-card class="gl-mb-4" />
        <visualize-and-lint-card class="gl-mb-4" />
        <pipeline-config-reference-card />
        <div class="gl-h-13"></div>
      </div>
    </aside>
  </local-storage-sync>
</template>
