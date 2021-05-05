<script>
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CommitSection from './components/commit/commit_section.vue';
import PipelineEditorDrawer from './components/drawer/pipeline_editor_drawer.vue';
import PipelineEditorFileNav from './components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorHeader from './components/header/pipeline_editor_header.vue';
import PipelineEditorTabs from './components/pipeline_editor_tabs.vue';
import { TABS_WITH_COMMIT_FORM, CREATE_TAB } from './constants';

export default {
  components: {
    CommitSection,
    PipelineEditorDrawer,
    PipelineEditorFileNav,
    PipelineEditorHeader,
    PipelineEditorTabs,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
    ciFileContent: {
      type: String,
      required: true,
    },
    isNewCiConfigFile: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      currentTab: CREATE_TAB,
    };
  },
  computed: {
    showCommitForm() {
      return TABS_WITH_COMMIT_FORM.includes(this.currentTab);
    },
    showPipelineDrawer() {
      return this.glFeatures.pipelineEditorDrawer;
    },
  },
  methods: {
    setCurrentTab(tabName) {
      this.currentTab = tabName;
    },
  },
};
</script>

<template>
  <div class="gl-pr-9 gl-transition-medium gl-w-full">
    <pipeline-editor-file-nav v-on="$listeners" />
    <pipeline-editor-header
      :ci-config-data="ciConfigData"
      :is-new-ci-config-file="isNewCiConfigFile"
    />
    <pipeline-editor-tabs
      :ci-config-data="ciConfigData"
      :ci-file-content="ciFileContent"
      v-on="$listeners"
      @set-current-tab="setCurrentTab"
    />
    <commit-section v-if="showCommitForm" :ci-file-content="ciFileContent" v-on="$listeners" />
    <pipeline-editor-drawer v-if="showPipelineDrawer" />
  </div>
</template>
