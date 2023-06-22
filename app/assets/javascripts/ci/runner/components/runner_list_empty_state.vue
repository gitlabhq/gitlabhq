<script>
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import FILTERED_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg?url';

import { GlEmptyState, GlLink, GlSprintf, GlModalDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';
import {
  I18N_GET_STARTED,
  I18N_RUNNERS_ARE_AGENTS,
  I18N_CREATE_RUNNER_LINK,
  I18N_STILL_USING_REGISTRATION_TOKENS,
  I18N_CONTACT_ADMIN_TO_REGISTER,
  I18N_NO_RESULTS,
  I18N_EDIT_YOUR_SEARCH,
} from '~/ci/runner/constants';

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
  svgHeight: 145,
  EMPTY_STATE_SVG_URL,
  FILTERED_SVG_URL,

  I18N_GET_STARTED,
  I18N_RUNNERS_ARE_AGENTS,
  I18N_CREATE_RUNNER_LINK,
  I18N_STILL_USING_REGISTRATION_TOKENS,
  I18N_CONTACT_ADMIN_TO_REGISTER,
  I18N_NO_RESULTS,
  I18N_EDIT_YOUR_SEARCH,
};
</script>

<template>
  <gl-empty-state
    v-if="isSearchFiltered"
    :title="$options.I18N_NO_RESULTS"
    :svg-path="$options.FILTERED_SVG_URL"
    :svg-height="$options.svgHeight"
    :description="$options.I18N_EDIT_YOUR_SEARCH"
  />
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
