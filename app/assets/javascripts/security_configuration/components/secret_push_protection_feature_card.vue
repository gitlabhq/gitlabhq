<script>
import {
  GlCard,
  GlIcon,
  GlLink,
  GlPopover,
  GlToggle,
  GlAlert,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';
import ProjectSetSecretPushProtection from '~/security_configuration/graphql/set_secret_push_protection.graphql';
import { __, s__ } from '~/locale';

export default {
  name: 'SecretPushProtectionFeatureCard',
  components: {
    GlCard,
    GlIcon,
    GlLink,
    GlPopover,
    GlToggle,
    GlAlert,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'secretPushProtectionAvailable',
    'secretPushProtectionEnforced',
    'secretPushProtectionEnabled',
    'userIsProjectAdmin',
    'projectFullPath',
    'secretDetectionConfigurationPath',
  ],
  props: {
    feature: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      projectToggleValue: this.secretPushProtectionEnabled,
      errorMessage: '',
      isAlertDismissed: false,
    };
  },
  computed: {
    shouldShowAlert() {
      return this.errorMessage && !this.isAlertDismissed;
    },
    available() {
      return this.feature.available;
    },
    isEnforced() {
      return this.secretPushProtectionAvailable && this.secretPushProtectionEnforced;
    },
    enabled() {
      if (this.isEnforced) {
        return true;
      }

      if (!this.secretPushProtectionAvailable) {
        return false;
      }

      return this.available && this.projectToggleValue;
    },
    cardClasses() {
      return { 'gl-bg-strong': !this.available };
    },
    textClasses() {
      return { 'gl-text-subtle': !this.available };
    },
    statusClasses() {
      const { enabled } = this;

      return {
        'gl-ml-auto': true,
        'gl-shrink-0': true,
        'gl-text-disabled': !enabled,
        'gl-text-success': enabled,
      };
    },
    isToggleDisabled() {
      const toggleable = this.userIsProjectAdmin || this.feature.canUserConfigure;
      return this.isEnforced || !this.secretPushProtectionAvailable || !toggleable;
    },
    showLock() {
      return this.isToggleDisabled && this.available;
    },
    featureLockDescription() {
      if (this.isEnforced) {
        return this.$options.i18n.enforcedTooltipDescription;
      }
      if (!this.secretPushProtectionAvailable) {
        return this.$options.i18n.tooltipDescription;
      }
      if (!this.userIsProjectAdmin && !this.feature.canUserConfigure) {
        return this.$options.i18n.accessLevelTooltipDescription;
      }
      return '';
    },
    availabilityText() {
      if (this.isGitlabCom) {
        return this.$options.i18n.availableWithUltimateAndPublic;
      }
      return this.$options.i18n.availableWith;
    },
    statusText() {
      if (this.isEnforced) {
        return this.$options.i18n.enforcedStatus;
      }
      if (this.enabled) {
        return this.$options.i18n.enabled;
      }
      if (!this.secretPushProtectionAvailable) {
        return this.$options.i18n.disabledAtInstance;
      }
      if (this.available) {
        return this.$options.i18n.notEnabled;
      }
      return this.availabilityText;
    },
    showLicenseUpgradeHint() {
      return !this.available && this.secretPushProtectionAvailable;
    },
  },
  watch: {
    secretPushProtectionEnabled(value) {
      if (!this.isEnforced) {
        this.projectToggleValue = value;
      }
    },
    secretPushProtectionEnforced(value) {
      if (value) {
        this.projectToggleValue = true;
      }
    },
  },
  methods: {
    reportError(error) {
      this.errorMessage = error;
      this.isAlertDismissed = false;
    },
    async toggleSecretPushProtection(checked) {
      if (this.isToggleDisabled) {
        return;
      }

      try {
        const { data } = await this.$apollo.mutate({
          mutation: ProjectSetSecretPushProtection,
          variables: {
            input: {
              namespacePath: this.projectFullPath,
              enable: checked,
            },
          },
        });

        const { errors, secretPushProtectionEnabled } = data.setSecretPushProtection;

        if (errors.length > 0) {
          this.reportError(errors[0].message);
        }
        if (secretPushProtectionEnabled !== null) {
          this.projectToggleValue = secretPushProtectionEnabled;
          this.$toast.show(
            secretPushProtectionEnabled
              ? this.$options.i18n.toastMessageEnabled
              : this.$options.i18n.toastMessageDisabled,
          );
        }
      } catch (error) {
        this.reportError(error);
      }
    },
  },
  i18n: {
    enabled: s__('SecurityConfiguration|Enabled'),
    enforcedStatus: s__('SecurityConfiguration|Enforced by administrator'),
    disabledAtInstance: s__('SecurityConfiguration|Restricted by administrator'),
    notEnabled: s__('SecurityConfiguration|Not enabled'),
    availableWith: s__('SecurityConfiguration|Available with Ultimate'),
    availableWithUltimateAndPublic: s__(
      'SecurityConfiguration|Available with Ultimate. Enabled by default for all public projects.',
    ),
    learnMore: __('Learn more'),
    tooltipTitle: s__('SecretDetection|Action unavailable'),
    tooltipDescription: s__(
      'SecretDetection|This feature has been restricted for all projects in the instance. Contact an administrator to request activation.',
    ),
    enforcedTooltipDescription: s__(
      'SecretDetection|This feature has been enforced for all projects in the instance by an administrator.',
    ),
    accessLevelTooltipDescription: s__(
      'SecretDetection|Only security managers, maintainers, and owners can toggle this feature.',
    ),
    toastMessageEnabled: s__('SecretDetection|Secret push protection is enabled'),
    toastMessageDisabled: s__('SecretDetection|Secret push protection is disabled'),
    settingsButtonTooltip: s__('SecretDetection|Configure Secret Detection'),
    toggleLabel: s__('SecurityConfiguration|Toggle secret push protection'),
  },
};
</script>

<template>
  <gl-card :class="cardClasses" body-class="gl-flex gl-flex-col gl-grow">
    <template #header>
      <div class="gl-flex gl-items-baseline">
        <h3 class="gl-m-0 gl-mr-3 gl-text-base" :class="textClasses">
          {{ feature.name }}
          <gl-icon v-if="showLock" id="lockIcon" name="lock" />
        </h3>
        <gl-popover target="lockIcon" placement="right">
          <template #title> {{ $options.i18n.tooltipTitle }} </template>
          <slot>
            {{ featureLockDescription }}
          </slot>
        </gl-popover>

        <div
          :class="statusClasses"
          data-testid="feature-status"
          :data-qa-feature="`${feature.type}_${enabled}_status`"
        >
          <template v-if="enabled">
            <span>
              <gl-icon name="check-circle-filled" />
              <span class="gl-text-success">{{ statusText }}</span>
            </span>
          </template>

          <template v-else>
            <span>{{ statusText }}</span>
          </template>
        </div>
      </div>
    </template>

    <p class="gl-mb-0 gl-grow" :class="textClasses">
      {{ feature.description }}
      <gl-link :href="feature.helpPath" target="_blank">{{ $options.i18n.learnMore }}.</gl-link>
    </p>

    <template v-if="available">
      <gl-alert
        v-if="shouldShowAlert"
        class="gl-mb-5 gl-mt-2"
        variant="danger"
        @dismiss="isAlertDismissed = true"
        >{{ errorMessage }}</gl-alert
      >
      <div class="gl-mt-5 gl-flex gl-justify-between">
        <gl-toggle
          class="gl-mt-2"
          :disabled="isToggleDisabled"
          :value="enabled"
          :label="$options.i18n.toggleLabel"
          label-position="hidden"
          @change="toggleSecretPushProtection"
        />
        <gl-button
          v-if="secretPushProtectionAvailable"
          v-gl-tooltip.left.viewport="$options.i18n.settingsButtonTooltip"
          icon="settings"
          category="secondary"
          :href="secretDetectionConfigurationPath"
        />
      </div>
    </template>

    <template v-else-if="showLicenseUpgradeHint">
      <div class="gl-mt-5">
        <span :class="textClasses">{{ availabilityText }}</span>
      </div>
    </template>
  </gl-card>
</template>
