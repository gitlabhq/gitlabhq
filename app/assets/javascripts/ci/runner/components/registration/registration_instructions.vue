<script>
import { GlIcon, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

import { EXECUTORS_HELP_URL, SERVICE_COMMANDS_HELP_URL } from '../../constants';
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
    platform: {
      type: String,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    token: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    commandPrompt() {
      return commandPrompt({ platform: this.platform });
    },
    registerCommand() {
      return registerCommand({ platform: this.platform, registrationToken: this.token });
    },
    runCommand() {
      return runCommand({ platform: this.platform });
    },
  },
  methods: {
    toggleDrawer(val) {
      this.$emit('toggleDrawer', val);
    },
  },
  EXECUTORS_HELP_URL,
  SERVICE_COMMANDS_HELP_URL,
};
</script>
<template>
  <div>
    <p>
      <gl-sprintf
        :message="
          s__(
            'Runners|GitLab Runner must be installed before you can register a runner. %{linkStart}How do I install GitLab Runner?%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link @click="toggleDrawer()">{{ content }}</gl-link>
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
            <gl-link :href="$options.EXECUTORS_HELP_URL">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </section>
    <section>
      <h2 class="gl-font-size-h2">{{ s__('Runners|Optional. Step 3') }}</h2>
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
            <gl-link :href="$options.SERVICE_COMMANDS_HELP_URL">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </section>
  </div>
</template>
