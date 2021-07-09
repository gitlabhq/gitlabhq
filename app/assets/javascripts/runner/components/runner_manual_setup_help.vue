<script>
import { GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import MaskedValue from '~/runner/components/helpers/masked_value.vue';
import RunnerRegistrationTokenReset from '~/runner/components/runner_registration_token_reset.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import RunnerInstructions from '~/vue_shared/components/runner_instructions/runner_instructions.vue';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../constants';

export default {
  components: {
    GlLink,
    GlSprintf,
    ClipboardButton,
    MaskedValue,
    RunnerInstructions,
    RunnerRegistrationTokenReset,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    runnerInstallHelpPage: {
      default: null,
    },
  },
  props: {
    registrationToken: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      required: true,
      validator(type) {
        return [INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE].includes(type);
      },
    },
  },
  data() {
    return {
      currentRegistrationToken: this.registrationToken,
    };
  },
  computed: {
    rootUrl() {
      return gon.gitlab_url || '';
    },
    typeName() {
      switch (this.type) {
        case INSTANCE_TYPE:
          return s__('Runners|shared');
        case GROUP_TYPE:
          return s__('Runners|group');
        case PROJECT_TYPE:
          return s__('Runners|specific');
        default:
          return '';
      }
    },
  },
  methods: {
    onTokenReset(token) {
      this.currentRegistrationToken = token;
    },
  },
};
</script>

<template>
  <div class="bs-callout">
    <h5 data-testid="runner-help-title">
      <gl-sprintf :message="__('Set up a %{type} runner manually')">
        <template #type>
          {{ typeName }}
        </template>
      </gl-sprintf>
    </h5>

    <ol>
      <li>
        <gl-link :href="runnerInstallHelpPage" data-testid="runner-help-link" target="_blank">
          {{ __("Install GitLab Runner and ensure it's running.") }}
        </gl-link>
      </li>
      <li>
        {{ __('Register the runner with this URL:') }}
        <br />

        <code data-testid="coordinator-url">{{ rootUrl }}</code>
        <clipboard-button :title="__('Copy URL')" :text="rootUrl" />
      </li>
      <li>
        {{ __('And this registration token:') }}
        <br />

        <code data-testid="registration-token"
          ><masked-value :value="currentRegistrationToken"
        /></code>
        <clipboard-button :title="__('Copy token')" :text="currentRegistrationToken" />
      </li>
    </ol>

    <runner-registration-token-reset :type="type" @tokenReset="onTokenReset" />

    <runner-instructions />
  </div>
</template>
