<script>
import { GlSprintf, GlLink, GlModalDirective } from '@gitlab/ui';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import { DEFAULT_PLATFORM } from '../constants';

export default {
  name: 'AdminNewRunnerApp',
  components: {
    GlLink,
    GlSprintf,
    RunnerInstructionsModal,
    RunnerPlatformsRadioGroup,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
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
  modalId: 'runners-legacy-registration-instructions-modal',
};
</script>

<template>
  <div>
    <h1 class="gl-font-size-h2">{{ s__('Runners|New instance runner') }}</h1>
    <p>
      <gl-sprintf
        :message="
          s__(
            'Runners|Create an instance runner to generate a command that registers the runner with all its configurations. %{linkStart}Prefer to use a registration token to create a runner?%{linkEnd}',
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

    <hr />

    <h2 class="gl-font-weight-normal gl-font-lg gl-my-5">
      {{ s__('Runners|Platform') }}
    </h2>
    <runner-platforms-radio-group v-model="platform" />
  </div>
</template>
