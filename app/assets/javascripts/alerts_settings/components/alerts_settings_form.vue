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
import MappingBuilder from './alert_mapping_builder.vue';
import AlertSettingsFormHelpBlock from './alert_settings_form_help_block.vue';
import getCurrentIntegrationQuery from '../graphql/queries/get_current_integration.query.graphql';
import service from '../services';
import {
  integrationTypesNew,
  JSON_VALIDATE_DELAY,
  targetPrometheusUrlPlaceholder,
  targetOpsgenieUrlPlaceholder,
  typeSet,
  sectionHash,
} from '../constants';
// Mocks will be removed when integrating with BE is ready
// data format is defined and will be the same as mocked (maybe with some minor changes)
// feature rollout plan - https://gitlab.com/gitlab-org/gitlab/-/issues/262707#note_442529171
import mockedCustomMapping from './mocks/parsedMapping.json';

export default {
  placeholders: {
    prometheus: targetPrometheusUrlPlaceholder,
    opsgenie: targetOpsgenieUrlPlaceholder,
  },
  JSON_VALIDATE_DELAY,
  typeSet,
  i18n: {
    integrationFormSteps: {
      step1: {
        label: s__('AlertSettings|1. Select integration type'),
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
          "AlertSettings|Utilize the URL and authorization key below to authorize an external service to send alerts to GitLab. Review your external service's documentation to learn where to add these details, and the %{linkStart}GitLab documentation%{linkEnd} to learn more about configuring your endpoint.",
        ),
        prometheusHelp: s__(
          'AlertSettings|Utilize the URL and authorization key below to authorize Prometheus to send alerts to GitLab. Review the Prometheus documentation to learn where to add these details, and the %{linkStart}GitLab documentation%{linkEnd} to learn more about configuring your endpoint.',
        ),
        info: s__('AlertSettings|Authorization key'),
        reset: s__('AlertSettings|Reset Key'),
      },
      step4: {
        label: s__('AlertSettings|4. Sample alert payload (optional)'),
        help: s__(
          'AlertSettings|Provide an example payload from the monitoring tool you intend to integrate with. This payload can be used to create a custom mapping (optional), or to test the integration (also optional).',
        ),
        prometheusHelp: s__(
          'AlertSettings|Provide an example payload from the monitoring tool you intend to integrate with. This payload can be used to test the integration (optional).',
        ),
        placeholder: s__('AlertSettings|{ "events": [{ "application": "Name of application" }] }'),
        resetHeader: s__('AlertSettings|Reset the mapping'),
        resetBody: s__(
          "AlertSettings|If you edit the payload, the stored mapping will be reset, and you'll need to re-map the fields.",
        ),
        resetOk: s__('AlertSettings|Proceed with editing'),
        editPayload: s__('AlertSettings|Edit payload'),
        submitPayload: s__('AlertSettings|Submit payload'),
        payloadParsedSucessMsg: s__(
          'AlertSettings|Sample payload has been parsed. You can now map the fields.',
        ),
      },
      step5: {
        label: s__('AlertSettings|5. Map fields (optional)'),
        intro: s__(
          "AlertSettings|If you've provided a sample alert payload, you can create a custom mapping for your endpoint. The default GitLab alert keys are listed below. Please define which payload key should map to the specified GitLab key.",
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
      // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
      opsgenie: {
        label: s__('AlertSettings|2. Add link to your Opsgenie alert list'),
        info: s__(
          'AlertSettings|Utilizing this option will link the GitLab Alerts navigation item to your existing Opsgenie instance. By selecting this option, you cannot receive alerts from any other source in GitLab; it will effectively be turning Alerts within GitLab off as a feature.',
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
    // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
    opsgenie: {
      default: {},
    },
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
    canAddIntegration: {
      type: Boolean,
      required: true,
    },
    // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
    canManageOpsgenie: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  apollo: {
    currentIntegration: {
      query: getCurrentIntegrationQuery,
    },
  },
  data() {
    return {
      selectedIntegration: integrationTypesNew[0].value,
      active: false,
      formVisible: false,
      integrationTestPayload: {
        json: null,
        error: null,
      },
      resetSamplePayloadConfirmed: false,
      customMapping: null,
      parsingPayload: false,
      currentIntegration: null,
      // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
      isManagingOpsgenie: false,
    };
  },
  computed: {
    isPrometheus() {
      return this.selectedIntegration === this.$options.typeSet.prometheus;
    },
    jsonIsValid() {
      return this.integrationTestPayload.error === null;
    },
    // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
    disabledIntegrations() {
      const options = [];
      if (this.opsgenie.active) {
        options.push(typeSet.http, typeSet.prometheus);
      } else if (!this.canManageOpsgenie) {
        options.push(typeSet.opsgenie);
      }

      return options;
    },
    options() {
      return integrationTypesNew.map(el => ({
        ...el,
        disabled: this.disabledIntegrations.includes(el.value),
      }));
    },
    selectedIntegrationType() {
      switch (this.selectedIntegration) {
        case typeSet.http:
          return this.generic;
        case typeSet.prometheus:
          return this.prometheus;
        // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
        case typeSet.opsgenie:
          return this.opsgenie;
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
      return this.customMapping?.samplePayload?.payloadAlerFields?.nodes;
    },
    mappingBuilderMapping() {
      return this.customMapping?.storedMapping?.nodes;
    },
    hasSamplePayload() {
      return Boolean(this.customMapping?.samplePayload);
    },
    canEditPayload() {
      return this.hasSamplePayload && !this.resetSamplePayloadConfirmed;
    },
    isResetAuthKeyDisabled() {
      return !this.active && !this.integrationForm.token !== '';
    },
    isPayloadEditDisabled() {
      return this.glFeatures.multipleHttpIntegrationsCustomMapping
        ? !this.active || this.canEditPayload
        : !this.active;
    },
    isSubmitTestPayloadDisabled() {
      return (
        !this.active ||
        Boolean(this.integrationTestPayload.error) ||
        this.integrationTestPayload.json === ''
      );
    },
  },
  watch: {
    currentIntegration(val) {
      if (val === null) {
        return this.reset();
      }
      this.selectedIntegration = val.type;
      this.active = val.active;
      if (val.type === typeSet.http && this.showMappingBuilder) this.getIntegrationMapping(val.id);
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

      // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
      if (this.canManageOpsgenie && this.selectedIntegration === typeSet.opsgenie) {
        this.isManagingOpsgenie = true;
        this.active = this.opsgenie.active;
        this.integrationForm.apiUrl = this.opsgenie.opsgenieMvcTargetUrl;
      } else {
        // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
        this.isManagingOpsgenie = false;
      }
    },
    // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
    submitWithOpsgenie() {
      return service
        .updateGenericActive({
          endpoint: this.opsgenie.formPath,
          params: {
            service: {
              opsgenie_mvc_target_url: this.integrationForm.apiUrl,
              opsgenie_mvc_enabled: this.active,
            },
          },
        })
        .then(() => {
          window.location.hash = sectionHash;
          window.location.reload();
        });
    },
    submitWithTestPayload() {
      this.$emit('set-test-alert-payload', this.testAlertPayload);
      this.submit();
    },
    submit() {
      // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
      if (this.isManagingOpsgenie) {
        return this.submitWithOpsgenie();
      }

      const { name, apiUrl } = this.integrationForm;
      const variables =
        this.selectedIntegration === typeSet.http
          ? { name, active: this.active }
          : { apiUrl, active: this.active };
      const integrationPayload = { type: this.selectedIntegration, variables };

      if (this.currentIntegration) {
        return this.$emit('update-integration', integrationPayload);
      }

      this.reset();
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

      // TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657
      this.isManagingOpsgenie = false;
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

          this.$toast.show(this.$options.i18n.integrationFormSteps.step4.payloadParsedSucessMsg);
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

      <div v-if="!canAddIntegration" class="gl-my-4" data-testid="multi-integrations-not-supported">
        <alert-settings-form-help-block
          :message="$options.i18n.integrationFormSteps.step1.enterprise"
          link="https://about.gitlab.com/pricing"
        />
      </div>
    </gl-form-group>
    <gl-collapse v-model="formVisible" class="gl-mt-3">
      <!-- TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657 -->
      <div v-if="isManagingOpsgenie">
        <gl-form-group
          id="integration-webhook"
          :label="$options.i18n.integrationFormSteps.opsgenie.label"
          label-for="integration-webhook"
        >
          <span class="gl-my-4">
            {{ $options.i18n.integrationFormSteps.opsgenie.info }}
          </span>

          <gl-toggle
            v-model="active"
            :is-loading="loading"
            :label="__('Active')"
            class="gl-my-4 gl-font-weight-normal"
          />

          <gl-form-input
            id="opsgenie-opsgenieMvcTargetUrl"
            v-model="integrationForm.apiUrl"
            type="text"
            :placeholder="$options.placeholders.opsgenie"
          />

          <span class="gl-text-gray-400 gl-my-1">
            {{ $options.i18n.integrationFormSteps.prometheusFormUrl.help }}
          </span>
        </gl-form-group>
      </div>
      <div v-else>
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
            :message="
              isPrometheus
                ? $options.i18n.integrationFormSteps.step3.prometheusHelp
                : $options.i18n.integrationFormSteps.step3.help
            "
            link="https://docs.gitlab.com/ee/operations/incident_management/alert_integrations.html"
          />

          <gl-toggle
            v-model="active"
            :is-loading="loading"
            :label="__('Active')"
            class="gl-my-4 gl-font-weight-normal"
          />

          <div v-if="isPrometheus" class="gl-my-4">
            <span class="gl-font-weight-bold">
              {{ $options.i18n.integrationFormSteps.prometheusFormUrl.label }}
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

          <div class="gl-my-4">
            <span class="gl-font-weight-bold">
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
            <span class="gl-font-weight-bold">
              {{ $options.i18n.integrationFormSteps.step3.info }}
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
                  :title="__('Copy')"
                  class="gl-m-0!"
                />
              </template>
            </gl-form-input-group>

            <gl-button v-gl-modal.authKeyModal :disabled="isResetAuthKeyDisabled">
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
          :class="{ 'gl-mb-0!': showMappingBuilder }"
          :invalid-feedback="integrationTestPayload.error"
        >
          <alert-settings-form-help-block
            :message="
              isPrometheus || !showMappingBuilder
                ? $options.i18n.integrationFormSteps.step4.prometheusHelp
                : $options.i18n.integrationFormSteps.step4.help
            "
            :link="generic.alertsUsageUrl"
          />

          <gl-form-textarea
            id="test-payload"
            v-model.trim="integrationTestPayload.json"
            :disabled="isPayloadEditDisabled"
            :state="jsonIsValid"
            :placeholder="$options.i18n.integrationFormSteps.step4.placeholder"
            class="gl-my-3"
            :debounce="$options.JSON_VALIDATE_DELAY"
            rows="6"
            max-rows="10"
            @input="validateJson"
          />
        </gl-form-group>

        <template v-if="showMappingBuilder">
          <gl-button
            v-if="canEditPayload"
            v-gl-modal.resetPayloadModal
            data-testid="payload-action-btn"
            :disabled="!active"
            class="gl-mt-3"
          >
            {{ $options.i18n.integrationFormSteps.step4.editPayload }}
          </gl-button>

          <gl-button
            v-else
            data-testid="payload-action-btn"
            :class="{ 'gl-mt-3': integrationTestPayload.error }"
            :disabled="!active"
            :loading="parsingPayload"
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

        <gl-form-group
          v-if="showMappingBuilder"
          id="mapping-builder"
          class="gl-mt-5"
          :label="$options.i18n.integrationFormSteps.step5.label"
          label-for="mapping-builder"
        >
          <span>{{ $options.i18n.integrationFormSteps.step5.intro }}</span>
          <mapping-builder
            :payload-fields="mappingBuilderFields"
            :mapping="mappingBuilderMapping"
          />
        </gl-form-group>
      </div>
      <div class="gl-display-flex gl-justify-content-start gl-py-3">
        <gl-button
          type="submit"
          variant="success"
          class="js-no-auto-disable"
          data-testid="integration-form-submit"
          >{{ s__('AlertSettings|Save integration') }}
        </gl-button>
        <!-- TODO: Will be removed in 13.7 as part of: https://gitlab.com/gitlab-org/gitlab/-/issues/273657 -->
        <gl-button
          v-if="!isManagingOpsgenie"
          data-testid="integration-test-and-submit"
          :disabled="isSubmitTestPayloadDisabled"
          category="secondary"
          variant="success"
          class="gl-mx-3 js-no-auto-disable"
          @click="submitWithTestPayload"
          >{{ s__('AlertSettings|Save and test payload') }}</gl-button
        >
        <gl-button
          type="reset"
          class="js-no-auto-disable"
          :class="{ 'gl-ml-3': isManagingOpsgenie }"
          >{{ __('Cancel') }}</gl-button
        >
      </div>
    </gl-collapse>
  </gl-form>
</template>
