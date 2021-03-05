<script>
import {
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormSelect,
  GlFormInput,
  GlFormInputGroup,
  GlFormTextarea,
  GlModal,
  GlModalDirective,
  GlToggle,
  GlTabs,
  GlTab,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { isEmpty, omit } from 'lodash';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  integrationTypes,
  integrationSteps,
  createStepNumbers,
  editStepNumbers,
  JSON_VALIDATE_DELAY,
  targetPrometheusUrlPlaceholder,
  typeSet,
  viewCredentialsTabIndex,
  i18n,
} from '../constants';
import getCurrentIntegrationQuery from '../graphql/queries/get_current_integration.query.graphql';
import parseSamplePayloadQuery from '../graphql/queries/parse_sample_payload.query.graphql';
import MappingBuilder from './alert_mapping_builder.vue';
import AlertSettingsFormHelpBlock from './alert_settings_form_help_block.vue';

export default {
  placeholders: {
    prometheus: targetPrometheusUrlPlaceholder,
  },
  JSON_VALIDATE_DELAY,
  typeSet,
  integrationSteps,
  i18n,
  components: {
    ClipboardButton,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlFormTextarea,
    GlFormSelect,
    GlModal,
    GlToggle,
    GlTabs,
    GlTab,
    AlertSettingsFormHelpBlock,
    MappingBuilder,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    generic: {
      default: {},
    },
    prometheus: {
      default: {},
    },
    multiIntegrations: {
      default: false,
    },
    projectPath: {
      default: '',
    },
  },
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
    canAddIntegration: {
      type: Boolean,
      required: true,
    },
    alertFields: {
      type: Array,
      required: false,
      default: null,
    },
  },
  apollo: {
    currentIntegration: {
      query: getCurrentIntegrationQuery,
    },
  },
  data() {
    return {
      integrationTypesOptions: Object.values(integrationTypes),
      selectedIntegration: integrationTypes.none.value,
      active: false,
      samplePayload: {
        json: null,
        error: null,
      },
      testPayload: {
        json: null,
        error: null,
      },
      resetPayloadAndMappingConfirmed: false,
      mapping: [],
      parsingPayload: false,
      currentIntegration: null,
      parsedPayload: [],
      activeTabIndex: 0,
    };
  },
  computed: {
    isPrometheus() {
      return this.selectedIntegration === this.$options.typeSet.prometheus;
    },
    isHttp() {
      return this.selectedIntegration === this.$options.typeSet.http;
    },
    isCreating() {
      return !this.currentIntegration;
    },
    isSampePayloadValid() {
      return this.samplePayload.error === null;
    },
    isTestPayloadValid() {
      return this.testPayload.error === null;
    },
    selectedIntegrationType() {
      switch (this.selectedIntegration) {
        case typeSet.http:
          return this.generic;
        case typeSet.prometheus:
          return this.prometheus;
        default:
          return {};
      }
    },
    integrationForm() {
      return {
        name: this.currentIntegration?.name || '',
        active: this.currentIntegration?.active || false,
        token:
          this.currentIntegration?.token ||
          (this.selectedIntegrationType !== this.generic ? this.selectedIntegrationType.token : ''),
        url:
          this.currentIntegration?.url ||
          (this.selectedIntegrationType !== this.generic ? this.selectedIntegrationType.url : ''),
        apiUrl: this.currentIntegration?.apiUrl || '',
      };
    },
    testAlertPayload() {
      return {
        data: this.testPayload.json,
        endpoint: this.integrationForm.url,
        token: this.integrationForm.token,
      };
    },
    showMappingBuilder() {
      return (
        this.multiIntegrations &&
        this.glFeatures.multipleHttpIntegrationsCustomMapping &&
        this.isHttp &&
        this.alertFields?.length
      );
    },
    hasSamplePayload() {
      return this.isValidNonEmptyJSON(this.currentIntegration?.payloadExample);
    },
    canEditPayload() {
      return this.hasSamplePayload && !this.resetPayloadAndMappingConfirmed;
    },
    canParseSamplePayload() {
      return !this.active || !this.isSampePayloadValid || !this.samplePayload.json;
    },
    isResetAuthKeyDisabled() {
      return !this.active && !this.integrationForm.token !== '';
    },
    isPayloadEditDisabled() {
      return !this.active || this.canEditPayload;
    },
    isSelectDisabled() {
      return this.currentIntegration !== null || !this.canAddIntegration;
    },
    viewCredentialsHelpMsg() {
      return this.isPrometheus
        ? i18n.integrationFormSteps.setupCredentials.prometheusHelp
        : i18n.integrationFormSteps.setupCredentials.help;
    },
  },
  watch: {
    currentIntegration(val) {
      if (val === null) {
        this.reset();
        return;
      }
      const { type, active, payloadExample, payloadAlertFields, payloadAttributeMappings } = val;
      this.selectedIntegration = type;
      this.active = active;

      if (type === typeSet.http && this.showMappingBuilder) {
        this.parsedPayload = payloadAlertFields;
        this.samplePayload.json = this.isValidNonEmptyJSON(payloadExample) ? payloadExample : null;
        const mapping = payloadAttributeMappings.map((mappingItem) =>
          omit(mappingItem, '__typename'),
        );
        this.updateMapping(mapping);
      }
      this.activeTabIndex = viewCredentialsTabIndex;
      this.$el.scrollIntoView({ block: 'center' });
    },
  },
  methods: {
    isValidNonEmptyJSON(JSONString) {
      if (JSONString) {
        let parsed;
        try {
          parsed = JSON.parse(JSONString);
        } catch (error) {
          Sentry.captureException(error);
        }
        if (parsed) return !isEmpty(parsed);
      }
      return false;
    },
    sendTestAlert() {
      this.$emit('test-alert-payload', this.testAlertPayload);
    },
    submit() {
      const { name, apiUrl } = this.integrationForm;
      const customMappingVariables = this.glFeatures.multipleHttpIntegrationsCustomMapping
        ? {
            payloadAttributeMappings: this.mapping,
            payloadExample: this.samplePayload.json || '{}',
          }
        : {};

      const variables =
        this.selectedIntegration === typeSet.http
          ? { name, active: this.active, ...customMappingVariables }
          : { apiUrl, active: this.active };

      const integrationPayload = { type: this.selectedIntegration, variables };

      if (this.currentIntegration) {
        return this.$emit('update-integration', integrationPayload);
      }

      this.reset();
      return this.$emit('create-new-integration', integrationPayload);
    },
    reset() {
      this.resetFormValues();
      this.resetPayloadAndMapping();
      this.$emit('clear-current-integration', { type: this.currentIntegration?.type });
    },
    resetFormValues() {
      this.selectedIntegration = integrationTypes.none.value;
      this.integrationForm.name = '';
      this.integrationForm.apiUrl = '';
      this.samplePayload = {
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
    validateJson(isSamplePayload = true) {
      const payload = isSamplePayload ? this.samplePayload : this.testPayload;

      payload.error = null;
      if (payload.json === '') {
        return;
      }

      try {
        JSON.parse(payload.json);
      } catch (e) {
        payload.error = JSON.stringify(e.message);
      }
    },
    parseMapping() {
      this.parsingPayload = true;

      return this.$apollo
        .query({
          query: parseSamplePayloadQuery,
          variables: { projectPath: this.projectPath, payload: this.samplePayload.json },
        })
        .then(
          ({
            data: {
              project: { alertManagementPayloadFields },
            },
          }) => {
            this.parsedPayload = alertManagementPayloadFields;
            this.resetPayloadAndMappingConfirmed = false;

            this.$toast.show(
              this.$options.i18n.integrationFormSteps.setSamplePayload.payloadParsedSucessMsg,
            );
          },
        )
        .catch(({ message }) => {
          this.samplePayload.error = message;
        })
        .finally(() => {
          this.parsingPayload = false;
        });
    },
    updateMapping(mapping) {
      this.mapping = mapping;
    },
    resetPayloadAndMapping() {
      this.resetPayloadAndMappingConfirmed = true;
      this.parsedPayload = [];
      this.updateMapping([]);
    },
    getLabelWithStepNumber(step, label) {
      let stepNumber = editStepNumbers[step];

      if (this.isCreating) {
        stepNumber = createStepNumbers[step];
      }

      return stepNumber ? `${stepNumber}.${label}` : label;
    },
  },
};
</script>

<template>
  <gl-form class="gl-mt-6" @submit.prevent="submit" @reset.prevent="reset">
    <gl-tabs v-model="activeTabIndex">
      <gl-tab :title="$options.i18n.integrationTabs.configureDetails">
        <gl-form-group
          v-if="isCreating"
          id="integration-type"
          :label="
            getLabelWithStepNumber(
              $options.integrationSteps.selectType,
              $options.i18n.integrationFormSteps.selectType.label,
            )
          "
          label-for="integration-type"
        >
          <gl-form-select
            v-model="selectedIntegration"
            :disabled="isSelectDisabled"
            class="gl-max-w-full"
            :options="integrationTypesOptions"
          />

          <alert-settings-form-help-block
            v-if="!canAddIntegration"
            disabled="true"
            class="gl-display-inline-block gl-my-4"
            :message="$options.i18n.integrationFormSteps.selectType.enterprise"
            link="https://about.gitlab.com/pricing"
            data-testid="multi-integrations-not-supported"
          />
        </gl-form-group>
        <div class="gl-mt-3">
          <gl-form-group
            v-if="isHttp"
            id="name-integration"
            :label="
              getLabelWithStepNumber(
                $options.integrationSteps.nameIntegration,
                $options.i18n.integrationFormSteps.nameIntegration.label,
              )
            "
            label-for="name-integration"
          >
            <gl-form-input
              v-model="integrationForm.name"
              type="text"
              :placeholder="$options.i18n.integrationFormSteps.nameIntegration.placeholder"
            />
          </gl-form-group>

          <gl-toggle
            v-model="active"
            :is-loading="loading"
            :label="$options.i18n.integrationFormSteps.nameIntegration.activeToggle"
            class="gl-my-4 gl-font-weight-normal"
          />

          <div v-if="isPrometheus" class="gl-my-4">
            <span class="gl-font-weight-bold">
              {{
                getLabelWithStepNumber(
                  $options.integrationSteps.setPrometheusApiUrl,
                  $options.i18n.integrationFormSteps.prometheusFormUrl.label,
                )
              }}
            </span>

            <gl-form-input
              id="integration-apiUrl"
              v-model="integrationForm.apiUrl"
              type="text"
              :placeholder="$options.placeholders.prometheus"
            />

            <span class="gl-text-gray-400">
              {{ $options.i18n.integrationFormSteps.prometheusFormUrl.help }}
            </span>
          </div>

          <template v-if="showMappingBuilder">
            <gl-form-group
              data-testid="sample-payload-section"
              :label="
                getLabelWithStepNumber(
                  $options.integrationSteps.setSamplePayload,
                  $options.i18n.integrationFormSteps.setSamplePayload.label,
                )
              "
              label-for="sample-payload"
              class="gl-mb-0!"
              :invalid-feedback="samplePayload.error"
            >
              <alert-settings-form-help-block
                :message="$options.i18n.integrationFormSteps.setSamplePayload.testPayloadHelpHttp"
                :link="generic.alertsUsageUrl"
              />

              <gl-form-textarea
                id="sample-payload"
                v-model.trim="samplePayload.json"
                :disabled="isPayloadEditDisabled"
                :state="isSampePayloadValid"
                :placeholder="$options.i18n.integrationFormSteps.setSamplePayload.placeholder"
                class="gl-my-3"
                :debounce="$options.JSON_VALIDATE_DELAY"
                rows="6"
                max-rows="10"
                @input="validateJson"
              />
            </gl-form-group>

            <gl-button
              v-if="canEditPayload"
              v-gl-modal.resetPayloadModal
              data-testid="payload-action-btn"
              :disabled="!active"
              class="gl-mt-3"
            >
              {{ $options.i18n.integrationFormSteps.setSamplePayload.editPayload }}
            </gl-button>

            <gl-button
              v-else
              data-testid="payload-action-btn"
              :class="{ 'gl-mt-3': samplePayload.error }"
              :disabled="canParseSamplePayload"
              :loading="parsingPayload"
              @click="parseMapping"
            >
              {{ $options.i18n.integrationFormSteps.setSamplePayload.parsePayload }}
            </gl-button>
            <gl-modal
              modal-id="resetPayloadModal"
              :title="$options.i18n.integrationFormSteps.setSamplePayload.resetHeader"
              :ok-title="$options.i18n.integrationFormSteps.setSamplePayload.resetOk"
              ok-variant="danger"
              @ok="resetPayloadAndMapping"
            >
              {{ $options.i18n.integrationFormSteps.setSamplePayload.resetBody }}
            </gl-modal>

            <gl-form-group
              id="mapping-builder"
              class="gl-mt-5"
              :label="
                getLabelWithStepNumber(
                  $options.integrationSteps.customizeMapping,
                  $options.i18n.integrationFormSteps.mapFields.label,
                )
              "
              label-for="mapping-builder"
            >
              <span>{{ $options.i18n.integrationFormSteps.mapFields.intro }}</span>
              <mapping-builder
                :parsed-payload="parsedPayload"
                :saved-mapping="mapping"
                :alert-fields="alertFields"
                @onMappingUpdate="updateMapping"
              />
            </gl-form-group>
          </template>
        </div>

        <div class="gl-display-flex gl-justify-content-start gl-py-3">
          <gl-button
            type="submit"
            variant="confirm"
            class="js-no-auto-disable"
            data-testid="integration-form-submit"
          >
            {{ $options.i18n.saveIntegration }}
          </gl-button>

          <gl-button type="reset" class="gl-ml-3 js-no-auto-disable">{{
            $options.i18n.cancelAndClose
          }}</gl-button>
        </div>
      </gl-tab>

      <gl-tab :title="$options.i18n.integrationTabs.viewCredentials" :disabled="isCreating">
        <alert-settings-form-help-block
          :message="viewCredentialsHelpMsg"
          link="https://docs.gitlab.com/ee/operations/incident_management/alert_integrations.html"
        />

        <gl-form-group id="integration-webhook">
          <div class="gl-my-4">
            <span class="gl-font-weight-bold">
              {{ $options.i18n.integrationFormSteps.setupCredentials.webhookUrl }}
            </span>

            <gl-form-input-group id="url" readonly :value="integrationForm.url">
              <template #append>
                <clipboard-button
                  :text="integrationForm.url || ''"
                  :title="$options.i18n.copy"
                  class="gl-m-0!"
                />
              </template>
            </gl-form-input-group>
          </div>

          <div class="gl-my-4">
            <span class="gl-font-weight-bold">
              {{ $options.i18n.integrationFormSteps.setupCredentials.authorizationKey }}
            </span>

            <gl-form-input-group
              id="authorization-key"
              class="gl-mb-3"
              readonly
              :value="integrationForm.token"
            >
              <template #append>
                <clipboard-button
                  :text="integrationForm.token || ''"
                  :title="$options.i18n.copy"
                  class="gl-m-0!"
                />
              </template>
            </gl-form-input-group>
          </div>
        </gl-form-group>

        <gl-button v-gl-modal.authKeyModal :disabled="isResetAuthKeyDisabled" variant="danger">
          {{ $options.i18n.integrationFormSteps.setupCredentials.reset }}
        </gl-button>

        <gl-button type="reset" class="gl-ml-3 js-no-auto-disable">{{
          $options.i18n.cancelAndClose
        }}</gl-button>

        <gl-modal
          modal-id="authKeyModal"
          :title="$options.i18n.integrationFormSteps.setupCredentials.reset"
          :ok-title="$options.i18n.integrationFormSteps.setupCredentials.reset"
          ok-variant="danger"
          @ok="resetAuthKey"
        >
          {{ $options.i18n.integrationFormSteps.restKeyInfo.label }}
        </gl-modal>
      </gl-tab>

      <gl-tab :title="$options.i18n.integrationTabs.sendTestAlert" :disabled="isCreating">
        <gl-form-group id="test-integration" :invalid-feedback="testPayload.error">
          <alert-settings-form-help-block
            :message="$options.i18n.integrationFormSteps.setSamplePayload.testPayloadHelp"
            :link="generic.alertsUsageUrl"
          />

          <gl-form-textarea
            id="test-payload"
            v-model.trim="testPayload.json"
            :state="isTestPayloadValid"
            :placeholder="$options.i18n.integrationFormSteps.setSamplePayload.placeholder"
            class="gl-my-3"
            :debounce="$options.JSON_VALIDATE_DELAY"
            rows="6"
            max-rows="10"
            @input="validateJson(false)"
          />
        </gl-form-group>

        <gl-button
          :disabled="!isTestPayloadValid"
          data-testid="send-test-alert"
          variant="confirm"
          class="js-no-auto-disable"
          @click="sendTestAlert"
        >
          {{ $options.i18n.send }}
        </gl-button>

        <gl-button type="reset" class="gl-ml-3 js-no-auto-disable">{{
          $options.i18n.cancelAndClose
        }}</gl-button>
      </gl-tab>
    </gl-tabs>
  </gl-form>
</template>
