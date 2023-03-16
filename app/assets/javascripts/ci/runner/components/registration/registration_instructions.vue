<script>
import { GlIcon, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { s__, sprintf } from '~/locale';

import {
  EXECUTORS_HELP_URL,
  SERVICE_COMMANDS_HELP_URL,
  STATUS_ONLINE,
  I18N_REGISTRATION_SUCCESS,
} from '../../constants';
import CliCommand from './cli_command.vue';
import { commandPrompt, registerCommand, runCommand } from './utils';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSkeletonLoader,
    GlSprintf,
    ClipboardButton,
    CliCommand,
  },
  props: {
    runner: {
      type: Object,
      required: false,
      default: null,
    },
    platform: {
      type: String,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    description() {
      return this.runner?.description;
    },
    heading() {
      if (this.description) {
        return sprintf(
          s__('Runners|Register "%{runnerDescription}" runner'),
          {
            runnerDescription: this.description,
          },
          false,
        );
      }
      return s__('Runners|Register runner');
    },
    token() {
      return this.runner?.ephemeralAuthenticationToken;
    },
    status() {
      return this.runner?.status;
    },
    commandPrompt() {
      return commandPrompt({ platform: this.platform });
    },
    registerCommand() {
      return registerCommand({
        platform: this.platform,
        registrationToken: this.token,
        description: this.description,
      });
    },
    runCommand() {
      return runCommand({ platform: this.platform });
    },
  },
  methods: {
    toggleDrawer() {
      this.$emit('toggleDrawer');
    },
  },
  EXECUTORS_HELP_URL,
  SERVICE_COMMANDS_HELP_URL,
  STATUS_ONLINE,
  I18N_REGISTRATION_SUCCESS,
};
</script>
<template>
  <div>
    <h1 class="gl-font-size-h1">{{ heading }}</h1>

    <p>
      <gl-sprintf
        :message="
          s__(
            'Runners|GitLab Runner must be installed before you can register a runner. %{linkStart}How do I install GitLab Runner?%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link data-testid="runner-install-link" @click="toggleDrawer">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <section>
      <h2 class="gl-font-size-h2">{{ s__('Runners|Step 1') }}</h2>
      <p>
        {{
          s__(
            'Runners|Copy and paste the following command into your command line to register the runner.',
          )
        }}
      </p>
      <gl-skeleton-loader v-if="loading" />
      <template v-else>
        <cli-command :prompt="commandPrompt" :command="registerCommand" />
        <p>
          <gl-icon name="information-o" class="gl-text-blue-600!" />
          <gl-sprintf
            :message="
              s__(
                'Runners|The %{boldStart}runner token%{boldEnd} %{token} displays %{boldStart}only for a short time%{boldEnd}, and is stored in the %{codeStart}config.toml%{codeEnd} after you create the runner. It will not be visible once the runner is registered.',
              )
            "
          >
            <template #token>
              <code>{{ token }}</code>
              <clipboard-button
                :text="token"
                :title="__('Copy')"
                size="small"
                category="tertiary"
                class="gl-border-none!"
              />
            </template>
            <template #bold="{ content }"
              ><span class="gl-font-weight-bold">{{ content }}</span></template
            >
            <template #code="{ content }"
              ><code>{{ content }}</code></template
            >
          </gl-sprintf>
        </p>
      </template>
    </section>
    <section>
      <h2 class="gl-font-size-h2">{{ s__('Runners|Step 2') }}</h2>
      <p>
        <gl-sprintf
          :message="
            s__(
              'Runners|Choose an executor when prompted by the command line. Executors run builds in different environments. %{linkStart}Not sure which one to select?%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="$options.EXECUTORS_HELP_URL" target="_blank">
              {{ content }} <gl-icon name="external-link" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </section>
    <section>
      <h2 class="gl-font-size-h2">{{ s__('Runners|Step 3 (optional)') }}</h2>
      <p>{{ s__('Runners|Manually verify that the runner is available to pick up jobs.') }}</p>
      <cli-command :prompt="commandPrompt" :command="runCommand" />
      <p>
        <gl-sprintf
          :message="
            s__(
              'Runners|This may not be needed if you manage your runner as a %{linkStart}system or user service%{linkEnd}.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="$options.SERVICE_COMMANDS_HELP_URL" target="_blank">
              {{ content }} <gl-icon name="external-link" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </section>
    <section v-if="status == $options.STATUS_ONLINE">
      <h2 class="gl-font-size-h2">🎉 {{ $options.I18N_REGISTRATION_SUCCESS }}</h2>

      <p class="gl-pl-6">
        <gl-sprintf :message="s__('Runners|To view the runner, go to %{runnerListName}.')">
          <template #runnerListName>
            <span class="gl-font-weight-bold"><slot name="runner-list-name"></slot></span>
          </template>
        </gl-sprintf>
      </p>
    </section>
  </div>
</template>
