<script>
import { GlSprintf, GlModal } from '@gitlab/ui';
import { __ } from '~/locale';

import CliCommand from '~/ci/runner/components/registration/cli_command.vue';

export default {
  components: {
    GlSprintf,
    GlModal,
    CliCommand,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    setupBashScript: {
      type: String,
      required: false,
      default: '',
    },
    setupTerraformFile: {
      type: String,
      required: false,
      default: '',
    },
    applyTerraformScript: {
      type: String,
      required: false,
      default: '',
    },
  },
  cancelModalOptions: {
    text: __('Close'),
  },
};
</script>

<template>
  <gl-modal
    cancel-variant="light"
    size="md"
    :scrollable="true"
    modal-id="setup-instructions"
    :action-cancel="$options.cancelModalOptions"
    :title="s__('Runners|Setup instructions')"
    :visible="visible"
    @change="$emit('change', $event)"
  >
    <p>
      {{
        s__(
          'Runners|These setup instructions use your specifications and follow the best practices for performance and security.',
        )
      }}
    </p>

    <h3 class="gl-heading-4">{{ s__('Runners|1. Configure your Google Cloud project') }}</h3>
    <p>
      {{
        s__(
          `Runners|Run the following command to enable the required services and create a service account with the required permissions. Only do this once for each Google Cloud project. You might be prompted to sign in to Google.`,
        )
      }}
    </p>
    <cli-command
      :command="setupBashScript"
      :button-title="s__('Runners|Copy commands')"
      modal-id="setup-instructions"
    />

    <h3 class="gl-heading-4">{{ s__('Runners|2. Install and register GitLab Runner') }}</h3>
    <p>
      {{
        s__(
          'Runners|Use Terraform to create the required infrastructure in Google Cloud, install GitLab Runner, and register it to this GitLab project.',
        )
      }}
    </p>
    <p>
      <gl-sprintf
        :message="
          s__(
            'Runners|Create a %{codeStart}main.tf%{codeEnd} file with the following Terraform configuration.',
          )
        "
      >
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
    <cli-command
      :command="setupTerraformFile"
      :button-title="s__('Runners|Copy Terraform configuration')"
      modal-id="setup-instructions"
    />

    <p>
      {{
        s__(
          'Runners|In the directory with that Terraform configuration file, run the following command to apply the configuration.',
        )
      }}
    </p>
    <cli-command
      :command="applyTerraformScript"
      :button-title="s__('Runners|Copy commands')"
      modal-id="setup-instructions"
    />

    <p>
      {{
        s__(
          'Runners|After GitLab Runner is installed and registered, an autoscaling fleet of runners can execute your CI/CD jobs in Google Cloud. Based on demand, a runner manager creates temporary runners.',
        )
      }}
    </p>
  </gl-modal>
</template>
