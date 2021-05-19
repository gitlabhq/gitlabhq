<script>
import { GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import RunnerInstructions from '~/vue_shared/components/runner_instructions/runner_instructions.vue';

export default {
  components: {
    GlLink,
    GlSprintf,
    ClipboardButton,
    RunnerInstructions,
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
    typeName: {
      type: String,
      required: false,
      default: __('shared'),
    },
  },
  computed: {
    rootUrl() {
      return gon.gitlab_url || '';
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

        <code data-testid="registration-token">{{ registrationToken }}</code>
        <clipboard-button :title="__('Copy token')" :text="registrationToken" />
      </li>
    </ol>

    <!-- TODO Implement reset token functionality -->
    <runner-instructions />
  </div>
</template>
