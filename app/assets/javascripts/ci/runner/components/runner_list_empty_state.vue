<script>
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';

import { GlEmptyState, GlLink, GlSprintf, GlModalDirective } from '@gitlab/ui';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import RunnerInstructionsModal from '~/ci/runner/components/registration/runner_instructions/runner_instructions_modal.vue';
import {
  I18N_GET_STARTED,
  I18N_RUNNERS_ARE_AGENTS,
  I18N_CREATE_RUNNER_LINK,
  I18N_STILL_USING_REGISTRATION_TOKENS,
  I18N_CONTACT_ADMIN_TO_REGISTER,
} from '~/ci/runner/constants';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
    EmptyResult,
    RunnerInstructionsModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    isSearchFiltered: {
      type: Boolean,
      required: false,
      default: false,
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
  modalId: 'runners-empty-state-instructions-modal',
  EMPTY_STATE_SVG_URL,

  I18N_GET_STARTED,
  I18N_RUNNERS_ARE_AGENTS,
  I18N_CREATE_RUNNER_LINK,
  I18N_STILL_USING_REGISTRATION_TOKENS,
  I18N_CONTACT_ADMIN_TO_REGISTER,
};
</script>

<template>
  <empty-result v-if="isSearchFiltered" />
  <gl-empty-state
    v-else
    :title="$options.I18N_GET_STARTED"
    :svg-path="$options.EMPTY_STATE_SVG_URL"
    :svg-height="$options.svgHeight"
  >
    <template #description>
      {{ $options.I18N_RUNNERS_ARE_AGENTS }}
      <gl-sprintf v-if="newRunnerPath" :message="$options.I18N_CREATE_RUNNER_LINK">
        <template #link="{ content }">
          <gl-link :href="newRunnerPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <template v-if="registrationToken">
        <br />
        <gl-link v-gl-modal="$options.modalId">{{
          $options.I18N_STILL_USING_REGISTRATION_TOKENS
        }}</gl-link>
        <runner-instructions-modal
          :modal-id="$options.modalId"
          :registration-token="registrationToken"
        />
      </template>
      <template v-if="!newRunnerPath && !registrationToken">
        {{ $options.I18N_CONTACT_ADMIN_TO_REGISTER }}
      </template>
    </template>
  </gl-empty-state>
</template>
