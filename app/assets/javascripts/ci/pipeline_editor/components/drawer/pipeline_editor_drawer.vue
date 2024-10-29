<script>
import { GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { __ } from '~/locale';
import { EDITOR_APP_DRAWER_NONE } from '~/ci/pipeline_editor/constants';
import FirstPipelineSection from './sections/first_pipeline_section.vue';
import GettingStartedSection from './sections/getting_started_section.vue';
import GitlabUniversitySection from './sections/gitlab_university_section.vue';
import PipelineConfigReferenceSection from './sections/pipeline_config_reference_section.vue';
import VisualizeAndLintSection from './sections/visualize_and_lint_section.vue';

export default {
  i18n: {
    title: __('Help'),
  },
  components: {
    FirstPipelineSection,
    GettingStartedSection,
    GitlabUniversitySection,
    GlDrawer,
    PipelineConfigReferenceSection,
    VisualizeAndLintSection,
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
      <h2 class="gl-m-0 gl-text-lg">{{ $options.i18n.title }}</h2>
    </template>
    <div class="gl-mb-5">
      <getting-started-section />
      <first-pipeline-section />
      <visualize-and-lint-section />
      <pipeline-config-reference-section />
      <gitlab-university-section />
    </div>
  </gl-drawer>
</template>
