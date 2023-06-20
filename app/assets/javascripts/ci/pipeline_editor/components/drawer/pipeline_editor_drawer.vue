<script>
import { GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { __ } from '~/locale';
import { EDITOR_APP_DRAWER_NONE } from '~/ci/pipeline_editor/constants';
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
    zIndex: {
      type: Number,
      required: false,
      default: DRAWER_Z_INDEX,
    },
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
  },
  methods: {
    closeDrawer() {
      this.$emit('switch-drawer', EDITOR_APP_DRAWER_NONE);
    },
  },
};
</script>
<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :open="isVisible"
    :z-index="zIndex"
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
