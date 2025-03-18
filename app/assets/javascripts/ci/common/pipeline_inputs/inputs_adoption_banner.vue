<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';

export default {
  name: 'InputsAdoptionBanner',
  components: { GlAlert, GlSprintf },
  inputsDocsPath: helpPagePath('ci/yaml/inputs'),
  inject: ['canViewPipelineEditor', 'pipelineEditorPath'],
  data() {
    return {
      isAlertVisible: true,
    };
  },
  computed: {
    showPipelineEditorButton() {
      return this.canViewPipelineEditor && this.pipelineEditorPath;
    },
    alertProps() {
      return {
        secondaryButtonText: __('Learn more'),
        secondaryButtonLink: this.$options.inputsDocsPath,
        ...(this.showPipelineEditorButton && {
          primaryButtonText: s__('Pipelines|Go to the pipeline editor'),
          primaryButtonLink: this.pipelineEditorPath,
        }),
      };
    },
  },
  methods: {
    closeAlert() {
      this.isAlertVisible = false;
    },
  },
};
</script>

<template>
  <gl-alert
    v-if="isAlertVisible"
    variant="tip"
    class="gl-my-4"
    v-bind="alertProps"
    @dismiss="closeAlert"
  >
    <gl-sprintf
      :message="
        s__(
          'Pipelines|Using %{codeStart}inputs%{codeEnd} to control pipeline behavior offers improved security and flexibility. Consider updating your pipelines to use %{codeStart}inputs%{codeEnd} instead.',
        )
      "
    >
      <template #code="{ content }">
        <code>{{ content }}</code>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
