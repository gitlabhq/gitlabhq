<script>
import { GlAlert, GlLoadingIcon, GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  CREATE_TAB,
  EDITOR_APP_STATUS_ERROR,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_VALID,
  LINT_TAB,
  MERGED_TAB,
  VISUALIZE_TAB,
} from '../constants';
import getAppStatus from '../graphql/queries/client/app_status.graphql';
import CiConfigMergedPreview from './editor/ci_config_merged_preview.vue';
import TextEditor from './editor/text_editor.vue';
import CiLint from './lint/ci_lint.vue';
import EditorTab from './ui/editor_tab.vue';

export default {
  i18n: {
    tabEdit: s__('Pipelines|Write pipeline configuration'),
    tabGraph: s__('Pipelines|Visualize'),
    tabLint: s__('Pipelines|Lint'),
    tabMergedYaml: s__('Pipelines|View merged YAML'),
  },
  errorTexts: {
    loadMergedYaml: s__('Pipelines|Could not load merged YAML content'),
  },
  tabConstants: {
    CREATE_TAB,
    LINT_TAB,
    MERGED_TAB,
    VISUALIZE_TAB,
  },
  components: {
    CiConfigMergedPreview,
    CiLint,
    EditorTab,
    GlAlert,
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
  },
  apollo: {
    appStatus: {
      query: getAppStatus,
    },
  },
  computed: {
    hasAppError() {
      // Not an invalid config and with `mergedYaml` data missing
      return this.appStatus === EDITOR_APP_STATUS_ERROR;
    },
    isValid() {
      return this.appStatus === EDITOR_APP_STATUS_VALID;
    },
    isLoading() {
      return this.appStatus === EDITOR_APP_STATUS_LOADING;
    },
  },
  methods: {
    setCurrentTab(tabName) {
      this.$emit('set-current-tab', tabName);
    },
  },
};
</script>
<template>
  <gl-tabs class="file-editor gl-mb-3">
    <editor-tab
      class="gl-mb-3"
      :title="$options.i18n.tabEdit"
      lazy
      data-testid="editor-tab"
      @click="setCurrentTab($options.tabConstants.CREATE_TAB)"
    >
      <text-editor :value="ciFileContent" v-on="$listeners" />
    </editor-tab>
    <gl-tab
      v-if="glFeatures.ciConfigVisualizationTab"
      class="gl-mb-3"
      :title="$options.i18n.tabGraph"
      lazy
      data-testid="visualization-tab"
      @click="setCurrentTab($options.tabConstants.VISUALIZE_TAB)"
    >
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-m-3" />
      <pipeline-graph v-else :pipeline-data="ciConfigData" />
    </gl-tab>
    <editor-tab
      class="gl-mb-3"
      :title="$options.i18n.tabLint"
      data-testid="lint-tab"
      @click="setCurrentTab($options.tabConstants.LINT_TAB)"
    >
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-m-3" />
      <ci-lint v-else :is-valid="isValid" :ci-config="ciConfigData" />
    </editor-tab>
    <gl-tab
      v-if="glFeatures.ciConfigMergedTab"
      class="gl-mb-3"
      :title="$options.i18n.tabMergedYaml"
      lazy
      data-testid="merged-tab"
      @click="setCurrentTab($options.tabConstants.MERGED_TAB)"
    >
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-m-3" />
      <gl-alert v-else-if="hasAppError" variant="danger" :dismissible="false">
        {{ $options.errorTexts.loadMergedYaml }}
      </gl-alert>
      <ci-config-merged-preview
        v-else
        :is-valid="isValid"
        :ci-config-data="ciConfigData"
        v-on="$listeners"
      />
    </gl-tab>
  </gl-tabs>
</template>
