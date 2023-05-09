<script>
import { GlEmptyState, GlLink, GlSprintf, GlModalDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
    RunnerInstructionsModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    isSearchFiltered: {
      type: Boolean,
      required: false,
      default: false,
    },
    svgPath: {
      type: String,
      required: false,
      default: '',
    },
    filteredSvgPath: {
      type: String,
      required: false,
      default: '',
    },
    registrationToken: {
      type: String,
      required: false,
      default: null,
    },
    newRunnerPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    shouldShowCreateRunnerWorkflow() {
      // create_runner_workflow_for_admin or create_runner_workflow_for_namespace
      return (
        this.newRunnerPath &&
        (this.glFeatures?.createRunnerWorkflowForAdmin ||
          this.glFeatures?.createRunnerWorkflowForNamespace)
      );
    },
  },
  modalId: 'runners-empty-state-instructions-modal',
  svgHeight: 145,
};
</script>

<template>
  <gl-empty-state
    v-if="isSearchFiltered"
    :title="s__('Runners|No results found')"
    :svg-path="filteredSvgPath"
    :svg-height="$options.svgHeight"
    :description="s__('Runners|Edit your search and try again')"
  />
  <gl-empty-state
    v-else
    :title="s__('Runners|Get started with runners')"
    :svg-path="svgPath"
    :svg-height="$options.svgHeight"
  >
    <template v-if="registrationToken" #description>
      <gl-sprintf
        :message="
          s__(
            'Runners|Runners are the agents that run your CI/CD jobs. Follow the %{linkStart}installation and registration instructions%{linkEnd} to set up a runner.',
          )
        "
      >
        <template v-if="shouldShowCreateRunnerWorkflow" #link="{ content }">
          <gl-link :href="newRunnerPath">{{ content }}</gl-link>
        </template>
        <template v-else #link="{ content }">
          <gl-link v-gl-modal="$options.modalId">{{ content }}</gl-link>
          <runner-instructions-modal
            :modal-id="$options.modalId"
            :registration-token="registrationToken"
          />
        </template>
      </gl-sprintf>
    </template>
    <template v-else #description>
      {{
        s__(
          'Runners|Runners are the agents that run your CI/CD jobs. To register new runners, please contact your administrator.',
        )
      }}
    </template>
  </gl-empty-state>
</template>
