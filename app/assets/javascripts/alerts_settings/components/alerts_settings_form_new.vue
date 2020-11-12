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
import MappingBuilder from './alert_mapping_builder.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import AlertSettingsFormHelpBlock from './alert_settings_form_help_block.vue';
import service from '../services';
import {
  integrationTypesNew,
  JSON_VALIDATE_DELAY,
  targetPrometheusUrlPlaceholder,
  typeSet,
} from '../constants';
// Mocks will be removed when integrating with BE is ready
// data format is defined and will be the same as mocked (maybe with some minor changes)
// feature rollout plan - https://gitlab.com/gitlab-org/gitlab/-/issues/262707#note_442529171
import mockedCustomMapping from './mocks/parsedMapping.json';

export default {
  targetPrometheusUrlPlaceholder,
  JSON_VALIDATE_DELAY,
  typeSet,
  i18n: {
    integrationFormSteps: {
      step1: {
        label: s__('AlertSettings|1. Select integration type'),
        help: s__('AlertSettings|Learn more about our upcoming %{linkStart}integrations%{linkEnd}'),
        enterprise: s__(
          'AlertSettings|In free versions of GitLab, only one integration for each type can be added. %{linkStart}Upgrade your subscription%{linkEnd} to add additional integrations.',
        ),
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
        resetHeader: s__('AlertSettings|Reset the mapping'),
        resetBody: s__(
          "AlertSettings|If you edit the payload, the stored mapping will be reset, and you'll need to re-map the fields.",
        ),
        resetOk: s__('AlertSettings|Proceed with editing'),
        editPayload: s__('AlertSettings|Edit payload'),
        submitPayload: s__('AlertSettings|Submit payload'),
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
      restKeyInfo: {
        label: s__(
          'AlertSettings|Resetting the authorization key for this project will require updating the authorization key in every alert source it is enabled in.',
        ),
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
    MappingBuilder,
  },
  directives: {
    GlModal: GlModalDirective,
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
    currentIntegration: {
      type: Object,
      required: false,
      default: null,
    },
    canAddIntegration: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      selectedIntegration: integrationTypesNew[0].value,
      options: integrationTypesNew,
      active: false,
      formVisible: false,
      integrationTestPayload: {
        json: null,
        error: null,
      },
      resetSamplePayloadConfirmed: false,
      customMapping: null,
      parsingPayload: false,
    };
  },
  computed: {
    jsonIsValid() {
      return this.integrationTestPayload.error === null;
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
    integrationForm() {
      return {
        name: this.currentIntegration?.name || '',
        active: this.currentIntegration?.active || false,
        token: this.currentIntegration?.token || this.selectedIntegrationType.token,
        url: this.currentIntegration?.url || this.selectedIntegrationType.url,
        apiUrl: this.currentIntegration?.apiUrl || '',
      };
    },
    testAlertPayload() {
      return {
        data: this.integrationTestPayload.json,
        endpoint: this.integrationForm.url,
        token: this.integrationForm.token,
      };
    },
    showMappingBuilder() {
      return (
        this.glFeatures.multipleHttpIntegrationsCustomMapping &&
        this.selectedIntegration === typeSet.http
      );
    },
    mappingBuilderFields() {
      return this.customMapping?.samplePayload?.payloadAlerFields?.nodes || [];
    },
    mappingBuilderMapping() {
      return this.customMapping?.storedMapping?.nodes || [];
    },
    hasSamplePayload() {
      return Boolean(this.customMapping?.samplePayload);
    },
    canEditPayload() {
      return this.hasSamplePayload && !this.resetSamplePayloadConfirmed;
    },
    isPayloadEditDisabled() {
      return !this.active || this.canEditPayload;
    },
  },
  watch: {
    currentIntegration(val) {
      if (val === null) {
        return this.reset();
      }
      this.selectedIntegration = val.type;
      this.active = val.active;
      if (val.type === typeSet.http) this.getIntegrationMapping(val.id);
      return this.integrationTypeSelect();
    },
  },
  methods: {
    integrationTypeSelect() {
      if (this.selectedIntegration === integrationTypesNew[0].value) {
        this.formVisible = false;
      } else {
        this.formVisible = true;
      }
    },
    submitWithTestPayload() {
      return service
        .updateTestAlert(this.testAlertPayload)
        .then(() => {
          this.submit();
        })
        .catch(() => {
          this.$emit('test-payload-failure');
        });
    },
    submit() {
      const { name, apiUrl } = this.integrationForm;
      const variables =
        this.selectedIntegration === this.$options.typeSet.http
          ? { name, active: this.active }
          : { apiUrl, active: this.active };
      const integrationPayload = { type: this.selectedIntegration, variables };

      if (this.currentIntegration) {
        return this.$emit('update-integration', integrationPayload);
      }

      return this.$emit('create-new-integration', integrationPayload);
    },
    reset() {
      this.selectedIntegration = integrationTypesNew[0].value;
      this.integrationTypeSelect();

      if (this.currentIntegration) {
        return this.$emit('clear-current-integration');
      }

      return this.resetFormValues();
    },
    resetFormValues() {
      this.integrationForm.name = '';
      this.integrationForm.apiUrl = '';
      this.integrationTestPayload = {
        json: null,
        error: null,
      };
      this.active = false;
    },
    resetAuthKey() {
      if (!this.currentIntegration) {
        return;
      }

      this.$emit('reset-token', {
        type: this.selectedIntegration,
        variables: { id: this.currentIntegration.id },
      });
    },
    validateJson() {
      this.integrationTestPayload.error = null;
      if (this.integrationTestPayload.json === '') {
        return;
      }

      try {
        JSON.parse(this.integrationTestPayload.json);
      } catch (e) {
        this.integrationTestPayload.error = JSON.stringify(e.message);
      }
    },
    parseMapping() {
      // TODO: replace with real BE mutation when ready;
      this.parsingPayload = true;

      return new Promise(resolve => {
        setTimeout(() => resolve(mockedCustomMapping), 1000);
      })
        .then(res => {
          const mapping = { ...res };
          delete mapping.storedMapping;
          this.customMapping = res;
          this.integrationTestPayload.json = res?.samplePayload.body;
          this.resetSamplePayloadConfirmed = false;
        })
        .finally(() => {
          this.parsingPayload = false;
        });
    },
    getIntegrationMapping() {
      // TODO: replace with real BE mutation when ready;
      return Promise.resolve(mockedCustomMapping).then(res => {
        this.customMapping = res;
        this.integrationTestPayload.json = res?.samplePayload.body;
      });
    },
  },
};
</script>

<template>
  <gl-form class="gl-mt-6" @submit.prevent="submit" @reset.prevent="reset">
    <h5 class="gl-font-lg gl-my-5">{{ s__('AlertSettings|Add new integrations') }}</h5>

    <gl-form-group
      id="integration-type"
      :label="$options.i18n.integrationFormSteps.step1.label"
      label-for="integration-type"
    >
      <gl-form-select
        v-model="selectedIntegration"
        :disabled="currentIntegration !== null || !canAddIntegration"
        :options="options"
        @change="integrationTypeSelect"
      />

      <div class="gl-my-4">
        <alert-settings-form-help-block
          :message="$options.i18n.integrationFormSteps.step1.help"
          link="https://gitlab.com/groups/gitlab-org/-/epics/4390"
        />
      </div>

      <div v-if="!canAddIntegration" class="gl-my-4" data-testid="multi-integrations-not-supported">
        <alert-settings-form-help-block
          :message="$options.i18n.integrationFormSteps.step1.enterprise"
          link="https://about.gitlab.com/pricing"
        />
      </div>
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
          v-model="active"
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

          <gl-form-input-group id="url" readonly :value="integrationForm.url">
            <template #append>
              <clipboard-button
                :text="integrationForm.url || ''"
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
            :value="integrationForm.token"
          >
            <template #append>
              <clipboard-button
                :text="integrationForm.token || ''"
                :title="__('Copy')"
                class="gl-m-0!"
              />
            </template>
          </gl-form-input-group>

          <gl-button v-gl-modal.authKeyModal :disabled="!active" class="gl-mt-3">
            {{ $options.i18n.integrationFormSteps.step3.reset }}
          </gl-button>
          <gl-modal
            modal-id="authKeyModal"
            :title="$options.i18n.integrationFormSteps.step3.reset"
            :ok-title="$options.i18n.integrationFormSteps.step3.reset"
            ok-variant="danger"
            @ok="resetAuthKey"
          >
            {{ $options.i18n.integrationFormSteps.restKeyInfo.label }}
          </gl-modal>
        </div>
      </gl-form-group>
      <gl-form-group
        id="test-integration"
        :label="$options.i18n.integrationFormSteps.step4.label"
        label-for="test-integration"
        :invalid-feedback="integrationTestPayload.error"
      >
        <alert-settings-form-help-block
          :message="$options.i18n.integrationFormSteps.step4.help"
          :link="generic.alertsUsageUrl"
        />

        <gl-form-textarea
          id="test-payload"
          v-model.trim="integrationTestPayload.json"
          :disabled="isPayloadEditDisabled"
          :state="jsonIsValid"
          :placeholder="$options.i18n.integrationFormSteps.step4.placeholder"
          class="gl-my-4"
          :debounce="$options.JSON_VALIDATE_DELAY"
          rows="6"
          max-rows="10"
          @input="validateJson"
        />

        <template v-if="showMappingBuilder">
          <gl-button
            v-if="canEditPayload"
            v-gl-modal.resetPayloadModal
            :disabled="!active"
            class="gl-mt-3"
          >
            {{ $options.i18n.integrationFormSteps.step4.editPayload }}
          </gl-button>

          <gl-button
            v-else
            :disabled="!active"
            :loading="parsingPayload"
            class="gl-mt-3"
            @click="parseMapping"
          >
            {{ $options.i18n.integrationFormSteps.step4.submitPayload }}
          </gl-button>
          <gl-modal
            modal-id="resetPayloadModal"
            :title="$options.i18n.integrationFormSteps.step4.resetHeader"
            :ok-title="$options.i18n.integrationFormSteps.step4.resetOk"
            ok-variant="danger"
            @ok="resetSamplePayloadConfirmed = true"
          >
            {{ $options.i18n.integrationFormSteps.step4.resetBody }}
          </gl-modal>
        </template>
      </gl-form-group>

      <gl-form-group
        v-if="showMappingBuilder"
        id="mapping-builder"
        :label="$options.i18n.integrationFormSteps.step5.label"
        label-for="mapping-builder"
      >
        <span class="gl-text-gray-500">{{ $options.i18n.integrationFormSteps.step5.intro }}</span>
        <mapping-builder :payload-fields="mappingBuilderFields" :mapping="mappingBuilderMapping" />
      </gl-form-group>
      <div class="gl-display-flex gl-justify-content-end">
        <gl-button type="reset" class="gl-mr-3 js-no-auto-disable">{{ __('Cancel') }}</gl-button>
        <gl-button
          data-testid="integration-test-and-submit"
          :disabled="Boolean(integrationTestPayload.error)"
          category="secondary"
          variant="success"
          class="gl-mr-1 js-no-auto-disable"
          @click="submitWithTestPayload"
          >{{ s__('AlertSettings|Save and test payload') }}</gl-button
        >
        <gl-button
          type="submit"
          variant="success"
          class="js-no-auto-disable"
          data-testid="integration-form-submit"
          >{{ s__('AlertSettings|Save integration') }}
        </gl-button>
      </div>
    </gl-collapse>
  </gl-form>
</template>
