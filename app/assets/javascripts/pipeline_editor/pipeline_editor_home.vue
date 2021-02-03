<script>
import CommitSection from './components/commit/commit_section.vue';
import PipelineEditorTabs from './components/pipeline_editor_tabs.vue';
import PipelineEditorHeader from './components/header/pipeline_editor_header.vue';

export default {
  components: {
    CommitSection,
    PipelineEditorHeader,
    PipelineEditorTabs,
  },
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
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <pipeline-editor-header
      :ci-config-data="ciConfigData"
      :is-ci-config-data-loading="isCiConfigDataLoading"
    />
    <pipeline-editor-tabs
      :ci-config-data="ciConfigData"
      :ci-file-content="ciFileContent"
      :is-ci-config-data-loading="isCiConfigDataLoading"
      v-on="$listeners"
    />
    <commit-section :ci-file-content="ciFileContent" v-on="$listeners" />
  </div>
</template>
