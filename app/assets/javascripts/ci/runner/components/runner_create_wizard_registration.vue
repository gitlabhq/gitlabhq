<script>
import {
  GlFormGroup,
  GlFormInputGroup,
  GlButton,
  GlSprintf,
  GlAlert,
  GlLoadingIcon,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import runnerForRegistrationQuery from '../graphql/register/runner_for_registration.query.graphql';
import { I18N_FETCH_ERROR } from '../constants';
import { captureException } from '../sentry_utils';

export default {
  components: {
    GlFormGroup,
    GlFormInputGroup,
    GlButton,
    GlSprintf,
    GlAlert,
    GlLoadingIcon,
    MultiStepFormTemplate,
    ClipboardButton,
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
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.runner.loading;
    },
  },
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

        <!-- instructions will be added in https://gitlab.com/gitlab-org/gitlab/-/issues/396544 -->
      </template>
    </template>
    <template v-if="!loading" #next>
      <gl-button category="primary" variant="default" :href="runnersPath">
        {{ s__('Runners|View runners') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>
