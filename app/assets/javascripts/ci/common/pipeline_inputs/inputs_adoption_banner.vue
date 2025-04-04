<script>
import { GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

export default {
  name: 'InputsAdoptionBanner',
  components: { GlAlert, GlButton, GlSprintf, UserCalloutDismisser },
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
  },
};
</script>

<template>
  <user-callout-dismisser :feature-name="featureName">
    <template #default="{ dismiss, shouldShowCallout }">
      <gl-alert v-if="shouldShowCallout" variant="tip" class="gl-my-4" @dismiss="dismiss">
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
        <div class="gl-mt-4 gl-flex gl-gap-3">
          <gl-button
            v-if="showPipelineEditorButton"
            :href="pipelineEditorPath"
            category="secondary"
            variant="confirm"
          >
            {{ __('Go to the pipeline editor') }}
          </gl-button>
          <gl-button :href="$options.inputsDocsPath" category="secondary" target="_blank">
            {{ __('Learn more') }}
          </gl-button>
        </div>
      </gl-alert>
    </template>
  </user-callout-dismisser>
</template>
