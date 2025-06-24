<script>
import { GlCard, GlIcon, GlLink, GlButton, GlToggle, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import ManageViaMr from '~/vue_shared/security_configuration/components/manage_via_mr.vue';
import SetValidityChecks from '~/security_configuration/graphql/set_validity_checks.graphql';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'PipelineSecretDetectionFeatureCard',
  validityChecksHelpUrl: helpPagePath('/user/application_security/vulnerabilities/validity_check'),
  components: {
    GlCard,
    GlIcon,
    GlLink,
    GlButton,
    GlToggle,
    GlAlert,
    ManageViaMr,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectFullPath', 'validityChecksEnabled', 'validityChecksAvailable'],
  props: {
    feature: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      localValidityChecksEnabled: this.validityChecksEnabled,
      errorMessage: '',
      isAlertDismissed: false,
    };
  },
  computed: {
    pipelineSecretDetectionAvailable() {
      return this.feature.available;
    },
    pipelineSecretDetectionEnabled() {
      return this.pipelineSecretDetectionAvailable && this.feature.configured;
    },
    shouldShowAlert() {
      return this.errorMessage && !this.isAlertDismissed;
    },
    cardClasses() {
      return { 'gl-bg-strong': !this.pipelineSecretDetectionAvailable };
    },
    textClasses() {
      return { 'gl-text-subtle': !this.pipelineSecretDetectionAvailable };
    },
    statusClasses() {
      const { pipelineSecretDetectionEnabled } = this;

      return {
        'gl-text-disabled': !pipelineSecretDetectionEnabled,
        'gl-text-success': pipelineSecretDetectionEnabled,
      };
    },
    hyphenatedFeature() {
      return this.feature.type.replace(/_/g, '-');
    },
    showManageViaMr() {
      return ManageViaMr.canRender(this.feature);
    },
    shouldRenderValidityChecks() {
      return this.glFeatures.validityChecks;
    },
    isToggleDisabled() {
      return !this.validityChecksAvailable || !this.pipelineSecretDetectionEnabled;
    },
  },
  methods: {
    onError(message) {
      this.$emit('error', message);
    },
    reportError(error) {
      this.errorMessage = error;
      this.isAlertDismissed = false;
    },
    async onValidityChecksToggle(checked) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: SetValidityChecks,
          variables: {
            input: {
              namespacePath: this.projectFullPath,
              enable: checked,
            },
          },
        });

        const { errors, validityChecksEnabled } = data.setValidityChecks;

        if (errors.length > 0) {
          this.reportError(errors[0]);
        }
        if (validityChecksEnabled !== null) {
          this.localValidityChecksEnabled = validityChecksEnabled;
          this.$toast.show(
            validityChecksEnabled
              ? s__('SecretDetection|Validity checks enabled')
              : s__('SecretDetection|Validity checks disabled'),
          );
        }
      } catch (error) {
        this.reportError(error);
      }
    },
  },
};
</script>

<template>
  <gl-card :class="cardClasses">
    <template #header>
      <div class="gl-flex gl-items-baseline">
        <h3 class="gl-m-0 gl-mr-3 gl-text-base" :class="textClasses">
          {{ feature.name }}
        </h3>
        <div
          class="gl-ml-auto gl-shrink-0"
          :class="statusClasses"
          data-testid="feature-status"
          :data-qa-feature="`${feature.type}_${pipelineSecretDetectionEnabled}_status`"
        >
          <template v-if="pipelineSecretDetectionEnabled">
            <gl-icon name="check-circle-filled" />
            <span class="gl-text-success">{{ s__('SecurityConfiguration|Enabled') }}</span>
          </template>

          <template v-else-if="pipelineSecretDetectionAvailable">
            <span>{{ s__('SecurityConfiguration|Not enabled') }}</span>
          </template>
        </div>
      </div>
    </template>

    <p class="gl-mb-0" :class="textClasses">
      {{ feature.description }}
      <gl-link :href="feature.helpPath" target="_blank">{{ __('Learn more') }}.</gl-link>
    </p>

    <template v-if="pipelineSecretDetectionAvailable">
      <div class="gl-mt-5 gl-flex gl-justify-between">
        <manage-via-mr
          v-if="showManageViaMr"
          :feature="feature"
          variant="confirm"
          category="primary"
          :data-testid="`${hyphenatedFeature}-mr-button`"
          @error="onError"
        />

        <gl-button
          v-else-if="feature.configurationHelpPath"
          icon="external-link"
          :href="feature.configurationHelpPath"
        >
          {{ s__('SecurityConfiguration|Configuration guide') }}
        </gl-button>
      </div>

      <div v-if="shouldRenderValidityChecks" class="gl-mt-6" data-testid="validity-checks-section">
        <gl-alert
          v-if="shouldShowAlert"
          class="gl-mb-5"
          variant="danger"
          @dismiss="isAlertDismissed = true"
        >
          {{ errorMessage }}
        </gl-alert>

        <h4 class="gl-mb-3 gl-text-base gl-font-bold">
          {{ s__('SecretDetection|Validity checks') }}
        </h4>

        <p class="gl-mb-4 gl-text-secondary">
          {{
            s__(
              'SecretDetection|Validate tokens using third-party API calls. When the pipeline is complete, your tokens are labeled Active, Possibly active, or Inactive. You must have pipeline secret detection enabled.',
            )
          }}
          <gl-link :href="$options.validityChecksHelpUrl" target="_blank">
            {{ s__('SecretDetection|What are validity checks?') }}
          </gl-link>
        </p>

        <div class="gl-flex gl-items-center">
          <gl-toggle
            v-model="localValidityChecksEnabled"
            :label="s__('SecretDetection|Validity checks')"
            label-position="hidden"
            data-testid="validity-checks-toggle"
            :disabled="isToggleDisabled"
            @change="onValidityChecksToggle"
          />
          <span class="gl-ml-3 gl-text-sm">
            {{
              localValidityChecksEnabled
                ? s__('SecurityConfiguration|Enabled')
                : s__('SecurityConfiguration|Not enabled')
            }}
          </span>
        </div>
      </div>
    </template>
  </gl-card>
</template>
