<script>
import { GlIcon, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { createAlert } from '~/alert';
import { s__, sprintf } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import RunnerGoogleCloudOption from '~/ci/runner/components/runner_google_cloud_option.vue';

import runnerForRegistrationQuery from '../../graphql/register/runner_for_registration.query.graphql';
import {
  STATUS_ONLINE,
  EXECUTORS_HELP_URL,
  SERVICE_COMMANDS_HELP_URL,
  RUNNER_REGISTRATION_POLLING_INTERVAL_MS,
  I18N_FETCH_ERROR,
  GOOGLE_CLOUD_PLATFORM,
  GOOGLE_KUBERNETES_ENGINE,
} from '../../constants';
import { captureException } from '../../sentry_utils';

import GoogleCloudRegistrationInstructions from './google_cloud_registration_instructions.vue';
import GkeRegistrationInstructions from './gke_registration_instructions.vue';
import PlatformsDrawer from './platforms_drawer.vue';
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
    GoogleCloudRegistrationInstructions,
    GkeRegistrationInstructions,
    PlatformsDrawer,
    RunnerPlatformsRadioGroup,
    RunnerGoogleCloudOption,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    platform: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: false,
      default: null,
    },
    groupPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      runner: null,
      token: null,
      isDrawerOpen: false,
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
          'Runners|The %{boldStart}runner authentication token%{boldEnd} %{token} displays here %{boldStart}for a short time only%{boldEnd}. After you register the runner, this token is stored in the %{codeStart}config.toml%{codeEnd} and cannot be accessed again from the UI.',
        );
      }
      return s__(
        'Runners|The %{boldStart}runner authentication token%{boldEnd} is no longer visible, it is stored in the %{codeStart}config.toml%{codeEnd} if you have registered the runner.',
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
    showGoogleCloudRegistration() {
      return this.platform === GOOGLE_CLOUD_PLATFORM;
    },
    showGKERegistration() {
      return this.platform === GOOGLE_KUBERNETES_ENGINE;
    },
  },
  watch: {
    isRunnerOnline(newVal, oldVal) {
      if (!oldVal && newVal) {
        this.$emit('runnerRegistered');
      }
    },
  },
  created() {
    window.addEventListener('beforeunload', this.onBeforeunload);
  },
  destroyed() {
    window.removeEventListener('beforeunload', this.onBeforeunload);
  },
  methods: {
    onSelectPlatform(event) {
      this.$emit('selectPlatform', event);
    },
    onToggleDrawer(val = !this.isDrawerOpen) {
      this.isDrawerOpen = val;
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
};
</script>
<template>
  <div class="gl-mt-5">
    <h1 class="gl-heading-1">{{ heading }}</h1>

    <h2 class="gl-heading-2">
      {{ s__('Runners|Platform') }}
    </h2>
    <runner-platforms-radio-group :value="platform" @input="onSelectPlatform">
      <template #cloud-options>
        <runner-google-cloud-option :checked="platform" @input="onSelectPlatform" />
      </template>
    </runner-platforms-radio-group>
    <hr aria-hidden="true" />

    <template v-if="showGoogleCloudRegistration || showGKERegistration">
      <template v-if="showGoogleCloudRegistration">
        <google-cloud-registration-instructions
          :token="token"
          :group-path="groupPath"
          :project-path="projectPath"
        />
      </template>
      <template v-if="showGKERegistration">
        <gke-registration-instructions
          :token="token"
          :group-path="groupPath"
          :project-path="projectPath"
        />
      </template>
    </template>
    <template v-else>
      <p>
        <gl-sprintf
          :message="
            s__(
              'Runners|GitLab Runner must be installed before you can register a runner. %{linkStart}How do I install GitLab Runner?%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link data-testid="how-to-install-btn" @click="onToggleDrawer()">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </p>

      <section class="gl-mt-6">
        <h2 class="gl-heading-2">{{ s__('Runners|Step 1') }}</h2>
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
            <gl-icon name="information-o" variant="info" />
            <gl-sprintf :message="tokenMessage">
              <template #token>
                <code data-testid="runner-token">{{ token }}</code>
                <clipboard-button
                  :text="token"
                  :title="__('Copy')"
                  size="small"
                  category="tertiary"
                />
              </template>
              <template #bold="{ content }"
                ><span class="gl-font-bold">{{ content }}</span></template
              >
              <template #code="{ content }"
                ><code>{{ content }}</code></template
              >
            </gl-sprintf>
          </p>
        </template>
      </section>
      <section class="gl-mt-6">
        <h2 class="gl-heading-2">{{ s__('Runners|Step 2') }}</h2>
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
      <section class="gl-mt-6">
        <h2 class="gl-heading-2">{{ s__('Runners|Step 3 (optional)') }}</h2>
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

      <platforms-drawer :platform="platform" :open="isDrawerOpen" @close="onToggleDrawer(false)" />
    </template>

    <section v-if="isRunnerOnline" class="gl-mt-6">
      <h2 class="gl-heading-2">🎉 {{ s__("Runners|You've registered a new runner!") }}</h2>

      <p>
        {{ s__('Runners|Your runner is online and ready to run jobs.') }}
      </p>

      <p class="gl-pl-6">
        <gl-sprintf :message="s__('Runners|To view the runner, go to %{runnerListName}.')">
          <template #runnerListName>
            <span class="gl-font-bold"><slot name="runner-list-name"></slot></span>
          </template>
        </gl-sprintf>
      </p>
    </section>
  </div>
</template>
