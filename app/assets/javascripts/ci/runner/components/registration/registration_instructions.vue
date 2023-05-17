<script>
import { GlIcon, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { createAlert } from '~/alert';
import { s__, sprintf } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';

import runnerForRegistrationQuery from '../../graphql/register/runner_for_registration.query.graphql';
import {
  STATUS_ONLINE,
  EXECUTORS_HELP_URL,
  SERVICE_COMMANDS_HELP_URL,
  RUNNER_REGISTRATION_POLLING_INTERVAL_MS,
  I18N_FETCH_ERROR,
  I18N_REGISTRATION_SUCCESS,
} from '../../constants';
import { captureException } from '../../sentry_utils';

import CliCommand from './cli_command.vue';
import { commandPrompt, registerCommand, runCommand } from './utils';

export default {
  name: 'RegistrationInstructions',
  components: {
    GlIcon,
    GlLink,
    GlSkeletonLoader,
    GlSprintf,
    ClipboardButton,
    CliCommand,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    platform: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      runner: null,
      token: null,
    };
  },
  apollo: {
    runner: {
      query: runnerForRegistrationQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_CI_RUNNER, this.runnerId),
        };
      },
      manual: true,
      result({ data }) {
        if (data?.runner) {
          const { ephemeralAuthenticationToken, ...runner } = data.runner;
          this.runner = runner;

          // The token is available in the API for a limited amount of time
          // preserve its original value if it is missing after polling.
          this.token = ephemeralAuthenticationToken || this.token;
        }
      },
      error(error) {
        createAlert({ message: I18N_FETCH_ERROR });
        captureException({ error, component: this.$options.name });
      },
      pollInterval() {
        if (this.isRunnerOnline) {
          // stop polling
          return 0;
        }
        return RUNNER_REGISTRATION_POLLING_INTERVAL_MS;
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.runner.loading;
    },
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
    tokenMessage() {
      if (this.token) {
        return s__(
          'Runners|The %{boldStart}runner token%{boldEnd} %{token} displays %{boldStart}only for a short time%{boldEnd}, and is stored in the %{codeStart}config.toml%{codeEnd} after you register the runner. It will not be visible once the runner is registered.',
        );
      }
      return s__(
        'Runners|The %{boldStart}runner token%{boldEnd} is no longer visible, it is stored in the %{codeStart}config.toml%{codeEnd} if you have registered the runner.',
      );
    },
    commandPrompt() {
      return commandPrompt({ platform: this.platform });
    },
    registerCommand() {
      return registerCommand({
        platform: this.platform,
        token: this.token,
      });
    },
    runCommand() {
      return runCommand({ platform: this.platform });
    },
    isRunnerOnline() {
      return this.runner?.status === STATUS_ONLINE;
    },
  },
  created() {
    window.addEventListener('beforeunload', this.onBeforeunload);
  },
  destroyed() {
    window.removeEventListener('beforeunload', this.onBeforeunload);
  },
  methods: {
    toggleDrawer() {
      this.$emit('toggleDrawer');
    },
    onBeforeunload(event) {
      if (this.isRunnerOnline) {
        return undefined;
      }

      const str = s__('Runners|You may lose access to the runner token if you leave this page.');
      event.preventDefault();
      // eslint-disable-next-line no-param-reassign
      event.returnValue = str; // Chrome requires returnValue to be set
      return str;
    },
  },
  EXECUTORS_HELP_URL,
  SERVICE_COMMANDS_HELP_URL,
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
          <gl-sprintf :message="tokenMessage">
            <template #token>
              <code data-testid="runner-token">{{ token }}</code>
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
    <section v-if="isRunnerOnline">
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
