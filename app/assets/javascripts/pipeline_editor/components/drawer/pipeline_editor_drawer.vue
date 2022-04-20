<script>
import { GlDrawer } from '@gitlab/ui';
import { __ } from '~/locale';
import FirstPipelineCard from './cards/first_pipeline_card.vue';
import GettingStartedCard from './cards/getting_started_card.vue';
import PipelineConfigReferenceCard from './cards/pipeline_config_reference_card.vue';
import VisualizeAndLintCard from './cards/visualize_and_lint_card.vue';

const DRAWER_CARD_STYLES = ['gl-border-bottom-0', 'gl-pt-6!', 'gl-pb-0!', 'gl-line-height-20'];

export default {
  DRAWER_CARD_STYLES,
  i18n: {
    title: __('Help'),
  },
  components: {
    FirstPipelineCard,
    GettingStartedCard,
    GlDrawer,
    PipelineConfigReferenceCard,
    VisualizeAndLintCard,
  },
  props: {
    isVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    drawerCardStyles() {
      return '';
    },
    drawerHeightOffset() {
      const wrapperEl = document.querySelector('.content-wrapper');
      return wrapperEl ? `${wrapperEl.offsetTop}px` : '';
    },
  },
  methods: {
    closeDrawer() {
      this.$emit('close-drawer');
    },
  },
};
</script>
<template>
  <gl-drawer
    :header-height="drawerHeightOffset"
    :open="isVisible"
    :z-index="200"
    @close="closeDrawer"
  >
    <template #title>
      <h2 class="gl-m-0 gl-font-lg">{{ $options.i18n.title }}</h2>
    </template>
    <getting-started-card :class="$options.DRAWER_CARD_STYLES" />
    <first-pipeline-card :class="$options.DRAWER_CARD_STYLES" />
    <visualize-and-lint-card :class="$options.DRAWER_CARD_STYLES" />
    <pipeline-config-reference-card :class="$options.DRAWER_CARD_STYLES" />
  </gl-drawer>
</template>
