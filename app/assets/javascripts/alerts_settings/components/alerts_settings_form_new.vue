<script>
import {
  GlButton,
  GlCollapse,
  GlForm,
  GlFormGroup,
  GlFormSelect,
  GlFormInput,
  GlFormInputGroup,
  GlFormTextarea,
  GlModal,
  GlModalDirective,
  GlToggle,
} from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import AlertSettingsFormHelpBlock from './alert_settings_form_help_block.vue';
import {
  integrationTypesNew,
  JSON_VALIDATE_DELAY,
  targetPrometheusUrlPlaceholder,
  typeSet,
} from '../constants';

export default {
  targetPrometheusUrlPlaceholder,
  JSON_VALIDATE_DELAY,
  typeSet,
  i18n: {
    integrationFormSteps: {
      step1: {
        label: s__('AlertSettings|1. Select integration type'),
        help: s__('AlertSettings|Learn more about our upcoming %{linkStart}integrations%{linkEnd}'),
      },
      step2: {
        label: s__('AlertSettings|2. Name integration'),
        placeholder: s__('AlertSettings|Enter integration name'),
      },
      step3: {
        label: s__('AlertSettings|3. Set up webhook'),
        help: s__(
          'AlertSettings|Utilize the URL and authorization key below to authorize an external service to send Alerts to GitLab. Review your chosen services documentation to learn where to add these details, and the %{linkStart}GitLab documentation%{linkEnd} to learn more about configuring your endpoint.',
        ),
        info: s__('AlertSettings|Authorization key'),
        reset: s__('AlertSettings|Reset Key'),
      },
      step4: {
        label: s__('AlertSettings|4. Test integration(optional)'),
        help: s__(
          'AlertSettings|Provide an example payload from the monitoring tool you intend to integrate with to send a test alert to the %{linkStart}alerts page%{linkEnd}. This payload can be used to test the integration using the "save and test payload" button.',
        ),
        placeholder: s__('AlertSettings|Enter test alert JSON....'),
      },
      step5: {
        label: s__('AlertSettings|5. Map fields (optional)'),
        intro: s__(
          'AlertSettings|The default GitLab alert keys are listed below. In the event an exact match could be found in the sample payload provided, that key will be mapped automatically. In all other cases, please define which payload key should map to the specified GitLab key. Any payload keys not shown in this list will not display in the alert list, but will display on the alert details page.',
        ),
      },
      prometheusFormUrl: {
        label: s__('AlertSettings|Prometheus API base URL'),
        help: s__('AlertSettings|URL cannot be blank and must start with http or https'),
      },
    },
  },
  components: {
    ClipboardButton,
    GlButton,
    GlCollapse,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlFormTextarea,
    GlFormSelect,
    GlModal,
    GlToggle,
    AlertSettingsFormHelpBlock,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  inject: {
    generic: {
      default: {},
    },
    prometheus: {
      default: {},
    },
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      selectedIntegration: integrationTypesNew[0].value,
      options: integrationTypesNew,
      formVisible: false,
      integrationForm: {
        name: '',
        integrationTestPayload: {
          json: null,
          error: null,
        },
        active: false,
        authKey: '',
        url: '',
        apiUrl: '',
      },
    };
  },
  computed: {
    jsonIsValid() {
      return this.integrationForm.integrationTestPayload.error === null;
    },
    selectedIntegrationType() {
      switch (this.selectedIntegration) {
        case this.$options.typeSet.http:
          return this.generic;
        case this.$options.typeSet.prometheus:
          return this.prometheus;
        default:
          return {};
      }
    },
  },
  methods: {
    onIntegrationTypeSelect() {
      if (this.selectedIntegration === integrationTypesNew[0].value) {
        this.formVisible = false;
      } else {
        this.formVisible = true;
      }
    },
    onSubmitWithTestPayload() {
      // TODO: Test payload before saving via GraphQL
      this.onSubmit();
    },
    onSubmit() {
      const { name, apiUrl, active } = this.integrationForm;
      const variables =
        this.selectedIntegration === this.$options.typeSet.http
          ? { name, active }
          : { apiUrl, active };
      this.$emit('on-create-new-integration', { type: this.selectedIntegration, variables });
    },
    onReset() {
      // TODO: Reset form values
    },
    onResetAuthKey() {
      // TODO: Handle reset auth key via GraphQL
    },
    validateJson() {
      this.integrationForm.integrationTestPayload.error = null;
      if (this.integrationForm.integrationTestPayload.json === '') {
        return;
      }

      try {
        JSON.parse(this.integrationForm.integrationTestPayload.json);
      } catch (e) {
        this.integrationForm.integrationTestPayload.error = JSON.stringify(e.message);
      }
    },
  },
};
</script>

<template>
  <gl-form class="gl-mt-6" @submit.prevent="onSubmit" @reset.prevent="onReset">
    <h5 class="gl-font-lg gl-my-5">{{ s__('AlertSettings|Add new integrations') }}</h5>

    <gl-form-group
      id="integration-type"
      :label="$options.i18n.integrationFormSteps.step1.label"
      label-for="integration-type"
    >
      <gl-form-select
        v-model="selectedIntegration"
        :options="options"
        @change="onIntegrationTypeSelect"
      />

      <alert-settings-form-help-block
        :message="$options.i18n.integrationFormSteps.step1.help"
        link="https://gitlab.com/groups/gitlab-org/-/epics/4390"
      />
    </gl-form-group>
    <gl-collapse v-model="formVisible" class="gl-mt-3">
      <gl-form-group
        id="name-integration"
        :label="$options.i18n.integrationFormSteps.step2.label"
        label-for="name-integration"
      >
        <gl-form-input
          v-model="integrationForm.name"
          type="text"
          :placeholder="$options.i18n.integrationFormSteps.step2.placeholder"
        />
      </gl-form-group>
      <gl-form-group
        id="integration-webhook"
        :label="$options.i18n.integrationFormSteps.step3.label"
        label-for="integration-webhook"
      >
        <alert-settings-form-help-block
          :message="$options.i18n.integrationFormSteps.step3.help"
          link="https://docs.gitlab.com/ee/operations/incident_management/alert_integrations.html"
        />

        <gl-toggle
          v-model="integrationForm.active"
          :is-loading="loading"
          :label="__('Active')"
          class="gl-my-4 gl-font-weight-normal"
        />

        <div v-if="selectedIntegration === $options.typeSet.prometheus" class="gl-my-4">
          <span>
            {{ $options.i18n.integrationFormSteps.prometheusFormUrl.label }}
          </span>

          <gl-form-input
            id="integration-apiUrl"
            v-model="integrationForm.apiUrl"
            type="text"
            :placeholder="$options.targetPrometheusUrlPlaceholder"
          />

          <span class="gl-text-gray-400">
            {{ $options.i18n.integrationFormSteps.prometheusFormUrl.help }}
          </span>
        </div>

        <div class="gl-my-4">
          <span>
            {{ s__('AlertSettings|Webhook URL') }}
          </span>

          <gl-form-input-group id="url" readonly :value="selectedIntegrationType.url">
            <template #append>
              <clipboard-button
                :text="selectedIntegrationType.url || ''"
                :title="__('Copy')"
                class="gl-m-0!"
              />
            </template>
          </gl-form-input-group>
        </div>

        <div class="gl-my-4">
          <span>
            {{ $options.i18n.integrationFormSteps.step3.info }}
          </span>

          <gl-form-input-group
            id="authorization-key"
            class="gl-mb-2"
            readonly
            :value="selectedIntegrationType.authKey"
          >
            <template #append>
              <clipboard-button
                :text="selectedIntegrationType.authKey || ''"
                :title="__('Copy')"
                class="gl-m-0!"
              />
            </template>
          </gl-form-input-group>

          <gl-button v-gl-modal.authKeyModal :disabled="!integrationForm.active" class="gl-mt-3">{{
            $options.i18n.integrationFormSteps.step3.reset
          }}</gl-button>
          <gl-modal
            modal-id="authKeyModal"
            :title="$options.i18n.integrationFormSteps.step3.reset"
            :ok-title="$options.i18n.integrationFormSteps.step3.reset"
            ok-variant="danger"
            @ok="() => {}"
          >
            {{ $options.i18n.integrationFormSteps.step3.reset }}
          </gl-modal>
        </div>
      </gl-form-group>
      <gl-form-group
        id="test-integration"
        :label="$options.i18n.integrationFormSteps.step4.label"
        label-for="test-integration"
        :invalid-feedback="integrationForm.integrationTestPayload.error"
      >
        <alert-settings-form-help-block
          :message="$options.i18n.integrationFormSteps.step4.help"
          :link="generic.alertsUsageUrl"
        />

        <gl-form-textarea
          id="test-integration"
          v-model.trim="integrationForm.integrationTestPayload.json"
          :disabled="!integrationForm.active"
          :state="jsonIsValid"
          :placeholder="$options.i18n.integrationFormSteps.step4.placeholder"
          class="gl-my-4"
          :debounce="$options.JSON_VALIDATE_DELAY"
          rows="6"
          max-rows="10"
          @input="validateJson"
        />
      </gl-form-group>

      <gl-form-group
        v-if="glFeatures.multipleHttpIntegrationsCustomMapping"
        id="mapping-builder"
        :label="$options.i18n.integrationFormSteps.step5.label"
        label-for="mapping-builder"
      >
        <span class="gl-text-gray-500">{{ $options.i18n.integrationFormSteps.step5.intro }}</span>
        <!--mapping builder will be added here-->
      </gl-form-group>
      <div class="gl-display-flex gl-justify-content-end">
        <gl-button type="reset" class="gl-mr-3 js-no-auto-disable">{{ __('Cancel') }}</gl-button>
        <gl-button
          category="secondary"
          variant="success"
          class="gl-mr-1 js-no-auto-disable"
          @click="onSubmitWithTestPayload"
          >{{ s__('AlertSettings|Save and test payload') }}</gl-button
        >
        <gl-button
          type="submit"
          variant="success"
          class="js-no-auto-disable"
          data-testid="integration-form-submit"
          >{{ s__('AlertSettings|Save integration') }}</gl-button
        >
      </div>
    </gl-collapse>
  </gl-form>
</template>
