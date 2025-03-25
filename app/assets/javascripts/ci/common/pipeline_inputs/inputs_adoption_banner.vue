<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

export default {
  name: 'InputsAdoptionBanner',
  components: { GlAlert, GlSprintf, UserCalloutDismisser },
  inputsDocsPath: helpPagePath('ci/yaml/inputs'),
  inject: ['canViewPipelineEditor', 'pipelineEditorPath'],
  props: {
    featureName: {
      type: String,
      required: true,
    },
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
};
</script>

<template>
  <user-callout-dismisser :feature-name="featureName">
    <template #default="{ dismiss, shouldShowCallout }">
      <gl-alert
        v-if="shouldShowCallout"
        variant="tip"
        class="gl-my-4"
        v-bind="alertProps"
        @dismiss="dismiss"
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
  </user-callout-dismisser>
</template>
