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
import { isEqual, isEmpty, omit } from 'lodash';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import {
  integrationTypes,
  integrationSteps,
  createStepNumbers,
  editStepNumbers,
  JSON_VALIDATE_DELAY,
  targetPrometheusUrlPlaceholder,
  typeSet,
  i18n,
  tabIndices,
  testAlertModalId,
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
  primaryProps: { text: i18n.integrationFormSteps.testPayload.savedAndTest },
  secondaryProps: { text: i18n.integrationFormSteps.testPayload.proceedWithoutSave },
  cancelProps: { text: i18n.integrationFormSteps.testPayload.cancel },
  testAlertModalId,
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
  inject: {
    alertsUsageUrl: {
      default: '#',
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
    tabIndex: {
      type: Number,
      required: false,
      default: tabIndices.configureDetails,
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
      samplePayload: {
        json: null,
        error: null,
        loading: false,
      },
      testPayload: {
        json: null,
        error: null,
      },
      resetPayloadAndMappingConfirmed: false,
      mapping: [],
      integrationForm: {
        active: false,
        type: integrationTypes.none.value,
        name: '',
        token: '',
        url: '',
        apiUrl: '',
      },
      activeTabIndex: this.tabIndex,
      currentIntegration: null,
      parsedPayload: [],
      validationState: {
        name: true,
        apiUrl: true,
      },
    };
  },
  computed: {
    isPrometheus() {
      return this.integrationForm.type === typeSet.prometheus;
    },
    isHttp() {
      return this.integrationForm.type === typeSet.http;
    },
    isNone() {
      return !this.isHttp && !this.isPrometheus;
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
    testAlertPayload() {
      return {
        data: this.testPayload.json,
        endpoint: this.integrationForm.url,
        token: this.integrationForm.token,
      };
    },
    showMappingBuilder() {
      return this.multiIntegrations && this.isHttp && this.alertFields?.length;
    },
    hasSamplePayload() {
      return this.isValidNonEmptyJSON(this.currentIntegration?.payloadExample);
    },
    canEditPayload() {
      return this.hasSamplePayload && !this.resetPayloadAndMappingConfirmed;
    },
    canParseSamplePayload() {
      return this.isSampePayloadValid && this.samplePayload.json;
    },
    isSelectDisabled() {
      return this.currentIntegration !== null || !this.canAddIntegration;
    },
    viewCredentialsHelpMsg() {
      return this.isPrometheus
        ? i18n.integrationFormSteps.setupCredentials.prometheusHelp
        : i18n.integrationFormSteps.setupCredentials.help;
    },
    isFormValid() {
      return (
        Object.values(this.validationState).every(Boolean) &&
        !this.isNone &&
        this.isSampePayloadValid
      );
    },
    isFormDirty() {
      const { type, active, name, apiUrl, payloadAlertFields = [], payloadAttributeMappings = [] } =
        this.currentIntegration || {};
      const {
        name: formName,
        apiUrl: formApiUrl,
        active: formActive,
        type: formType,
      } = this.integrationForm;

      const isDirty =
        type !== formType ||
        active !== formActive ||
        name !== formName ||
        apiUrl !== formApiUrl ||
        !isEqual(this.parsedPayload, payloadAlertFields) ||
        !isEqual(this.mapping, this.getCleanMapping(payloadAttributeMappings));

      return isDirty;
    },
    canSubmitForm() {
      return this.isFormValid && this.isFormDirty;
    },
    dataForSave() {
      const { name, apiUrl, active } = this.integrationForm;
      const customMappingVariables = {
        payloadAttributeMappings: this.mapping,
        payloadExample: this.samplePayload.json || '{}',
      };

      const variables = this.isHttp
        ? { name, active, ...customMappingVariables }
        : { apiUrl, active };

      return { type: this.integrationForm.type, variables };
    },
    testAlertModal() {
      return this.isFormDirty ? testAlertModalId : null;
    },
    prometheusUrlInvalidFeedback() {
      const { blankUrlError, invalidUrlError } = i18n.integrationFormSteps.prometheusFormUrl;
      return this.integrationForm.apiUrl?.length ? invalidUrlError : blankUrlError;
    },
  },
  watch: {
    tabIndex(val) {
      this.activeTabIndex = val;
    },
    currentIntegration(val) {
      if (val === null) {
        this.reset();
        return;
      }

      this.resetPayloadAndMapping();
      const {
        name,
        type,
        active,
        url,
        apiUrl,
        token,
        payloadExample,
        payloadAlertFields,
        payloadAttributeMappings,
      } = val;
      this.integrationForm = { type, name, active, url, apiUrl, token };

      if (this.showMappingBuilder) {
        this.resetPayloadAndMappingConfirmed = false;
        this.parsedPayload = payloadAlertFields;
        this.samplePayload.json = this.getPrettifiedPayload(payloadExample);
        this.updateMapping(this.getCleanMapping(payloadAttributeMappings));
      }
      this.$el.scrollIntoView({ block: 'center' });
    },
  },
  methods: {
    getCleanMapping(mapping) {
      return mapping.map((mappingItem) => omit(mappingItem, '__typename'));
    },
    validateName() {
      this.validationState.name = Boolean(this.integrationForm.name?.length);
    },
    validateApiUrl() {
      try {
        const parsedUrl = new URL(this.integrationForm.apiUrl);
        this.validationState.apiUrl = ['http:', 'https:'].includes(parsedUrl.protocol);
      } catch (e) {
        this.validationState.apiUrl = false;
      }
    },
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
    getPrettifiedPayload(payload) {
      return this.isValidNonEmptyJSON(payload)
        ? JSON.stringify(JSON.parse(payload), null, '\t')
        : null;
    },
    triggerValidation() {
      if (this.isHttp) {
        this.validationState.apiUrl = true;
        this.validateName();
        if (!this.validationState.name) {
          this.$refs.integrationName.$el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      } else if (this.isPrometheus) {
        this.validationState.name = true;
        this.validateApiUrl();
      }
    },
    sendTestAlert() {
      this.$emit('test-alert-payload', this.testAlertPayload);
    },
    saveAndSendTestAlert() {
      this.$emit('save-and-test-alert-payload', this.dataForSave, this.testAlertPayload);
    },
    submit(testAfterSubmit = false) {
      this.triggerValidation();

      if (!this.isFormValid) {
        return;
      }
      const event = this.currentIntegration ? 'update-integration' : 'create-new-integration';
      this.$emit(event, this.dataForSave, testAfterSubmit);
    },
    reset() {
      this.resetFormValues();
      this.resetPayloadAndMapping();
      this.$emit('clear-current-integration', { type: this.currentIntegration?.type });
    },
    resetFormValues() {
      this.integrationForm.type = integrationTypes.none.value;
      this.integrationForm.name = '';
      this.integrationForm.active = false;
      this.integrationForm.apiUrl = '';
      this.samplePayload = {
        json: null,
        error: null,
      };
    },
    resetAuthKey() {
      if (!this.currentIntegration) {
        return;
      }

      this.$emit('reset-token', {
        type: this.integrationForm.type,
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
    parseSamplePayload() {
      this.samplePayload.loading = true;

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
              this.$options.i18n.integrationFormSteps.mapFields.payloadParsedSucessMsg,
            );
          },
        )
        .catch(({ message }) => {
          this.samplePayload.error = message;
        })
        .finally(() => {
          this.samplePayload.loading = false;
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
      <gl-tab :title="$options.i18n.integrationTabs.configureDetails" class="gl-mt-3">
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
            v-model="integrationForm.type"
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
            :label="
              getLabelWithStepNumber(
                $options.integrationSteps.nameIntegration,
                $options.i18n.integrationFormSteps.nameIntegration.label,
              )
            "
            label-for="name-integration"
            :invalid-feedback="$options.i18n.integrationFormSteps.nameIntegration.error"
            :state="validationState.name"
          >
            <gl-form-input
              id="name-integration"
              ref="integrationName"
              v-model="integrationForm.name"
              type="text"
              :placeholder="$options.i18n.integrationFormSteps.nameIntegration.placeholder"
              @input="validateName"
            />
          </gl-form-group>

          <gl-form-group
            v-if="!isNone"
            :label="
              getLabelWithStepNumber(
                isHttp
                  ? $options.integrationSteps.enableHttpIntegration
                  : $options.integrationSteps.enablePrometheusIntegration,
                $options.i18n.integrationFormSteps.enableIntegration.label,
              )
            "
          >
            <span>{{ $options.i18n.integrationFormSteps.enableIntegration.help }}</span>

            <gl-toggle
              id="enable-integration"
              v-model="integrationForm.active"
              :is-loading="loading"
              :label="$options.i18n.integrationFormSteps.nameIntegration.activeToggle"
              class="gl-mt-4 gl-font-weight-normal"
            />
          </gl-form-group>

          <gl-form-group
            v-if="isPrometheus"
            class="gl-my-4"
            :label="$options.i18n.integrationFormSteps.prometheusFormUrl.label"
            label-for="api-url"
            :invalid-feedback="prometheusUrlInvalidFeedback"
            :state="validationState.apiUrl"
          >
            <gl-form-input
              id="api-url"
              v-model="integrationForm.apiUrl"
              type="text"
              :placeholder="$options.placeholders.prometheus"
              @input="validateApiUrl"
            />
            <span class="gl-text-gray-400">
              {{ $options.i18n.integrationFormSteps.prometheusFormUrl.help }}
            </span>
          </gl-form-group>

          <template v-if="showMappingBuilder">
            <gl-form-group
              data-testid="sample-payload-section"
              :label="
                getLabelWithStepNumber(
                  $options.integrationSteps.customizeMapping,
                  $options.i18n.integrationFormSteps.mapFields.label,
                )
              "
              label-for="sample-payload"
              class="gl-mb-0!"
              :invalid-feedback="samplePayload.error"
            >
              <span>{{ $options.i18n.integrationFormSteps.mapFields.help }}</span>

              <gl-form-textarea
                id="sample-payload"
                v-model="samplePayload.json"
                :disabled="canEditPayload"
                :state="isSampePayloadValid"
                :placeholder="$options.i18n.integrationFormSteps.mapFields.placeholder"
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
              :disabled="!integrationForm.active"
              class="gl-mt-3"
            >
              {{ $options.i18n.integrationFormSteps.mapFields.editPayload }}
            </gl-button>

            <gl-button
              v-else
              data-testid="payload-action-btn"
              :class="{ 'gl-mt-3': samplePayload.error }"
              :disabled="!canParseSamplePayload"
              :loading="samplePayload.loading"
              @click="parseSamplePayload"
            >
              {{ $options.i18n.integrationFormSteps.mapFields.parsePayload }}
            </gl-button>
            <gl-modal
              modal-id="resetPayloadModal"
              :title="$options.i18n.integrationFormSteps.mapFields.resetHeader"
              :ok-title="$options.i18n.integrationFormSteps.mapFields.resetOk"
              ok-variant="danger"
              @ok="resetPayloadAndMappingConfirmed = true"
            >
              {{ $options.i18n.integrationFormSteps.mapFields.resetBody }}
            </gl-modal>

            <div class="gl-mt-5">
              <span>{{ $options.i18n.integrationFormSteps.mapFields.mapIntro }}</span>
              <mapping-builder
                :parsed-payload="parsedPayload"
                :saved-mapping="mapping"
                :alert-fields="alertFields"
                @onMappingUpdate="updateMapping"
              />
            </div>
          </template>
        </div>
        <div class="gl-display-flex gl-justify-content-start gl-py-3">
          <gl-button
            :disabled="!canSubmitForm"
            variant="confirm"
            class="js-no-auto-disable"
            data-testid="integration-form-submit"
            @click="submit(false)"
          >
            {{ $options.i18n.saveIntegration }}
          </gl-button>

          <gl-button
            :disabled="!canSubmitForm"
            variant="confirm"
            category="secondary"
            class="gl-ml-3 js-no-auto-disable"
            data-testid="integration-form-test-and-submit"
            @click="submit(true)"
          >
            {{ $options.i18n.saveAndTestIntegration }}
          </gl-button>

          <gl-button type="reset" class="gl-ml-3 js-no-auto-disable">{{
            $options.i18n.cancelAndClose
          }}</gl-button>
        </div>
      </gl-tab>

      <gl-tab
        :title="$options.i18n.integrationTabs.viewCredentials"
        :disabled="isCreating"
        class="gl-mt-3"
      >
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

        <div class="gl-display-flex gl-justify-content-start gl-py-3">
          <gl-button v-gl-modal.authKeyModal variant="danger">
            {{ $options.i18n.integrationFormSteps.setupCredentials.reset }}
          </gl-button>

          <gl-button type="reset" class="gl-ml-3 js-no-auto-disable">
            {{ $options.i18n.cancelAndClose }}
          </gl-button>
        </div>

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

      <gl-tab
        :title="$options.i18n.integrationTabs.sendTestAlert"
        :disabled="isCreating"
        class="gl-mt-3"
      >
        <gl-form-group id="test-integration" :invalid-feedback="testPayload.error">
          <alert-settings-form-help-block
            :message="$options.i18n.integrationFormSteps.testPayload.help"
            :link="alertsUsageUrl"
          />

          <gl-form-textarea
            id="test-payload"
            v-model="testPayload.json"
            :state="isTestPayloadValid"
            :placeholder="$options.i18n.integrationFormSteps.testPayload.placeholder"
            class="gl-my-3"
            :debounce="$options.JSON_VALIDATE_DELAY"
            rows="6"
            max-rows="10"
            @input="validateJson(false)"
          />
        </gl-form-group>
        <div class="gl-display-flex gl-justify-content-start gl-py-3">
          <gl-button
            v-gl-modal="testAlertModal"
            :disabled="!isTestPayloadValid"
            :loading="loading"
            data-testid="send-test-alert"
            variant="confirm"
            class="js-no-auto-disable"
            @click="isFormDirty ? null : sendTestAlert()"
          >
            {{ $options.i18n.send }}
          </gl-button>

          <gl-button type="reset" class="gl-ml-3 js-no-auto-disable">
            {{ $options.i18n.cancelAndClose }}
          </gl-button>
        </div>

        <gl-modal
          :modal-id="$options.testAlertModalId"
          :title="$options.i18n.integrationFormSteps.testPayload.modalTitle"
          :action-primary="$options.primaryProps"
          :action-secondary="$options.secondaryProps"
          :action-cancel="$options.cancelProps"
          @primary="saveAndSendTestAlert"
          @secondary="sendTestAlert"
        >
          {{ $options.i18n.integrationFormSteps.testPayload.modalBody }}
        </gl-modal>
      </gl-tab>
    </gl-tabs>
  </gl-form>
</template>
