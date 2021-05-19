<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import PipelineEditorFileNav from '~/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlButton,
    GlSprintf,
    PipelineEditorFileNav,
  },
  i18n: {
    title: __('Optimize your workflow with CI/CD Pipelines'),
    body: __(
      'Create a new %{codeStart}.gitlab-ci.yml%{codeEnd} file at the root of the repository to get started.',
    ),
    btnText: __('Create new CI/CD pipeline'),
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    emptyStateIllustrationPath: {
      default: '',
    },
  },
  computed: {
    showFileNav() {
      return this.glFeatures.pipelineEditorBranchSwitcher;
    },
    showCTAButton() {
      return this.glFeatures.pipelineEditorEmptyStateAction;
    },
  },
  methods: {
    createEmptyConfigFile() {
      this.$emit('createEmptyConfigFile');
    },
  },
};
</script>
<template>
  <div>
    <pipeline-editor-file-nav v-if="showFileNav" v-on="$listeners" />
    <div class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-mt-11">
      <img :src="emptyStateIllustrationPath" />
      <h1 class="gl-font-size-h1">{{ $options.i18n.title }}</h1>
      <p class="gl-mt-3">
        <gl-sprintf :message="$options.i18n.body">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </p>
      <gl-button
        v-if="showCTAButton"
        variant="confirm"
        class="gl-mt-3"
        @click="createEmptyConfigFile"
      >
        {{ $options.i18n.btnText }}
      </gl-button>
    </div>
  </div>
</template>
