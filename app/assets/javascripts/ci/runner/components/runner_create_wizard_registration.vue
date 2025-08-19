<script>
import {
  GlFormGroup,
  GlFormInputGroup,
  GlButton,
  GlBadge,
  GlSprintf,
  GlAlert,
  GlLink,
  GlIcon,
  GlLoadingIcon,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import runnerForRegistrationQuery from '../graphql/register/runner_for_registration.query.graphql';
import {
  DOCKER_HELP_URL,
  KUBERNETES_HELP_URL,
  I18N_FETCH_ERROR,
  CREATION_STATE_FINISHED,
  RUNNER_REGISTRATION_POLLING_INTERVAL_MS,
} from '../constants';
import { captureException } from '../sentry_utils';
import OperatingSystemInstruction from './registration/wizard_operating_system_instruction.vue';
import GoogleCloudRegistrationInstructions from './registration/google_cloud_registration_instructions.vue';
import GkeRegistrationInstructions from './registration/gke_registration_instructions.vue';

export default {
  components: {
    GlFormGroup,
    GlFormInputGroup,
    GlButton,
    GlBadge,
    GlSprintf,
    GlAlert,
    GlLink,
    GlIcon,
    GlLoadingIcon,
    MultiStepFormTemplate,
    ClipboardButton,
    CrudComponent,
    OperatingSystemInstruction,
    GoogleCloudRegistrationInstructions,
    GkeRegistrationInstructions,
  },
  props: {
    currentStep: {
      type: Number,
      required: true,
    },
    stepsTotal: {
      type: Number,
      required: true,
    },
    runnerId: {
      type: String,
      required: true,
    },
    runnersPath: {
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
        if (this.isRunnerRegistered) {
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
    isRunnerRegistered() {
      return this.runner?.creationState === CREATION_STATE_FINISHED;
    },
  },
  DOCKER_HELP_URL,
  KUBERNETES_HELP_URL,
};
</script>
<template>
  <multi-step-form-template
    :title="s__('Runners|Register your new runner')"
    :current-step="currentStep"
    :steps-total="stepsTotal"
  >
    <template #form>
      <template v-if="loading">
        <div class="gl-text-center gl-text-base" data-testid="loading-icon-wrapper">
          <gl-loading-icon
            :label="s__('Runners|Loading')"
            size="md"
            variant="spinner"
            :inline="false"
            class="gl-mb-2"
          />
          {{ s__('Runners|Loading') }}
        </div>
      </template>
      <template v-else>
        <gl-form-group
          v-if="token"
          :label="s__('Runners|Runner authentication token')"
          label-for="token"
          class="gl-mb-7"
        >
          <template #description>
            <gl-sprintf
              :message="
                s__(
                  'Runners|The runner authentication token displays here %{boldStart}for a short time only%{boldEnd}. After you register the runner, this token is stored in the %{codeStart}config.toml%{codeEnd} and cannot be accessed again from the UI.',
                )
              "
            >
              <template #bold="{ content }">
                <b>{{ content }}</b>
              </template>
              <template #code="{ content }">
                <code>{{ content }}</code>
              </template>
            </gl-sprintf>
          </template>
          <gl-form-input-group
            id="token"
            readonly
            :value="token"
            class="gl-mb-3"
            data-testid="token-input"
          >
            <template #append>
              <clipboard-button
                :text="token"
                :title="__('Copy to clipboard')"
                data-testid="copy-token-to-clipboard"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>
        <gl-alert v-else variant="warning" :dismissible="false" class="gl-mb-7">
          <gl-sprintf
            :message="
              s__(
                'Runners|The %{boldStart}runner authentication token%{boldEnd} is no longer visible, it is stored in the %{codeStart}config.toml%{codeEnd} if you have registered the runner.',
              )
            "
          >
            <template #bold="{ content }">
              <b>{{ content }}</b>
            </template>
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
          </gl-sprintf>
        </gl-alert>

        <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
        <!-- Operating systems -->
        <operating-system-instruction
          platform="linux"
          :token="token"
          title="Linux"
          class="gl-rounded-b-none"
        />

        <operating-system-instruction
          platform="osx"
          :token="token"
          title="macOS"
          class="!gl-mt-0 gl-rounded-none gl-border-t-0"
        />

        <operating-system-instruction
          platform="windows"
          :token="token"
          title="Windows"
          class="!gl-mt-0 gl-rounded-none gl-border-t-0"
        />

        <!-- Clouds -->
        <crud-component
          is-collapsible
          :collapsed="true"
          :is-empty="false"
          class="!gl-mt-0 gl-rounded-none gl-border-t-0"
        >
          <template #title>
            Google Cloud
            <gl-badge variant="neutral">{{ s__('Runners|Cloud') }}</gl-badge>
          </template>
          <google-cloud-registration-instructions :is-widget="true" />
        </crud-component>

        <crud-component
          is-collapsible
          :collapsed="true"
          :is-empty="false"
          class="!gl-mt-0 gl-rounded-none gl-border-t-0"
        >
          <template #title>
            GKE
            <gl-badge variant="neutral">{{ s__('Runners|Cloud') }}</gl-badge>
          </template>
          <gke-registration-instructions :is-widget="true" />
        </crud-component>

        <!-- Containers -->
        <crud-component
          is-collapsible
          :collapsed="true"
          :is-empty="false"
          class="!gl-mt-0 gl-rounded-none gl-border-t-0"
        >
          <template #title>
            Docker
            <gl-badge variant="neutral">{{ s__('Runners|Container') }}</gl-badge>
          </template>
          <gl-sprintf :message="s__('Runners|View instructions in %{helpLink}.')">
            <template #helpLink>
              <gl-link :href="$options.DOCKER_HELP_URL" target="_blank">
                {{ s__('Runners|documentation') }}
                <gl-icon name="external-link" />
              </gl-link>
            </template>
          </gl-sprintf>
        </crud-component>

        <crud-component
          is-collapsible
          :collapsed="true"
          :is-empty="false"
          class="!gl-mt-0 gl-rounded-t-none gl-border-t-0"
        >
          <template #title>
            Kubernetes
            <gl-badge variant="neutral">{{ s__('Runners|Container') }}</gl-badge>
          </template>
          <gl-sprintf :message="s__('Runners|View instructions in %{helpLink}.')">
            <template #helpLink>
              <gl-link :href="$options.KUBERNETES_HELP_URL" target="_blank">
                {{ s__('Runners|documentation') }}
                <gl-icon name="external-link" />
              </gl-link>
            </template>
          </gl-sprintf>
        </crud-component>
      </template>
      <div
        v-if="isRunnerRegistered"
        class="gl-sticky gl-bottom-0 -gl-mb-4 gl-bg-alpha-light-36 gl-py-4 gl-backdrop-blur-sm"
        data-testid="runner-registered-alert"
      >
        <gl-alert variant="success" :dismissible="false">
          🎉
          {{
            s__(
              "Runners|You've registered a new runner! Your runner is online and ready to run jobs.",
            )
          }}
        </gl-alert>
      </div>
    </template>
    <template v-if="!loading" #next>
      <gl-button category="primary" variant="default" :href="runnersPath">
        {{ s__('Runners|View runners') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>
