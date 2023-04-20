<script>
import { GlSprintf, GlLink, GlModalDirective } from '@gitlab/ui';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { s__ } from '~/locale';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { DEFAULT_PLATFORM, PROJECT_TYPE } from '../constants';

export default {
  name: 'ProjectNewRunnerApp',
  components: {
    GlLink,
    GlSprintf,
    RunnerInstructionsModal,
    RunnerPlatformsRadioGroup,
    RunnerCreateForm,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    legacyRegistrationToken: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      platform: DEFAULT_PLATFORM,
    };
  },
  methods: {
    onSaved() {
      createAlert({
        message: s__('Runners|Runner created.'),
        variant: VARIANT_SUCCESS,
      });
    },
    onError(error) {
      createAlert({ message: error.message });
    },
  },
  modalId: 'runners-legacy-registration-instructions-modal',
  PROJECT_TYPE,
};
</script>

<template>
  <div>
    <h1 class="gl-font-size-h2">{{ s__('Runners|New project runner') }}</h1>
    <p>
      <gl-sprintf
        :message="
          s__(
            'Runners|Create a project runner to generate a command that registers the runner with all its configurations. %{linkStart}Prefer to use a registration token to create a runner?%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link v-gl-modal="$options.modalId" data-testid="legacy-instructions-link">{{
            content
          }}</gl-link>
          <runner-instructions-modal
            :modal-id="$options.modalId"
            :registration-token="legacyRegistrationToken"
          />
        </template>
      </gl-sprintf>
    </p>

    <hr aria-hidden="true" />

    <h2 class="gl-font-weight-normal gl-font-lg gl-my-5">
      {{ s__('Runners|Platform') }}
    </h2>
    <runner-platforms-radio-group v-model="platform" />

    <hr aria-hidden="true" />

    <runner-create-form
      :runner-type="$options.PROJECT_TYPE"
      :project-id="projectId"
      @saved="onSaved"
      @error="onError"
    />
  </div>
</template>
