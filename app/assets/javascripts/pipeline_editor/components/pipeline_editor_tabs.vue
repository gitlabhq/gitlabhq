<script>
import { GlLoadingIcon, GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CiLint from './lint/ci_lint.vue';
import EditorTab from './ui/editor_tab.vue';
import TextEditor from './text_editor.vue';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';

export default {
  i18n: {
    tabEdit: s__('Pipelines|Write pipeline configuration'),
    tabGraph: s__('Pipelines|Visualize'),
    tabLint: s__('Pipelines|Lint'),
  },
  components: {
    CiLint,
    EditorTab,
    GlLoadingIcon,
    GlTab,
    GlTabs,
    PipelineGraph,
    TextEditor,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
    ciFileContent: {
      type: String,
      required: true,
    },
    isCiConfigDataLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <gl-tabs class="file-editor gl-mb-3">
    <editor-tab :title="$options.i18n.tabEdit" lazy data-testid="editor-tab">
      <text-editor :value="ciFileContent" v-on="$listeners" />
    </editor-tab>
    <gl-tab
      v-if="glFeatures.ciConfigVisualizationTab"
      :title="$options.i18n.tabGraph"
      lazy
      data-testid="visualization-tab"
    >
      <gl-loading-icon v-if="isCiConfigDataLoading" size="lg" class="gl-m-3" />
      <pipeline-graph v-else :pipeline-data="ciConfigData" />
    </gl-tab>
    <editor-tab :title="$options.i18n.tabLint" data-testid="lint-tab">
      <gl-loading-icon v-if="isCiConfigDataLoading" size="lg" class="gl-m-3" />
      <ci-lint v-else :ci-config="ciConfigData" />
    </editor-tab>
  </gl-tabs>
</template>
