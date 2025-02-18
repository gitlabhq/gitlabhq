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
import ProjectPreReceiveSecretDetection from '~/security_configuration/graphql/set_pre_receive_secret_detection.graphql';
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
      toggleValue: this.secretPushProtectionEnabled,
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
    enabled() {
      return this.available && this.toggleValue;
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
      return !this.secretPushProtectionAvailable || !this.userIsProjectAdmin;
    },
    showLock() {
      return this.isToggleDisabled && this.available;
    },
    featureLockDescription() {
      if (!this.secretPushProtectionAvailable) {
        return this.$options.i18n.tooltipDescription;
      }
      if (!this.userIsProjectAdmin) {
        return this.$options.i18n.accessLevelTooltipDescription;
      }
      return '';
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
    async toggleSecretPushProtection(checked) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: ProjectPreReceiveSecretDetection,
          variables: {
            input: {
              namespacePath: this.projectFullPath,
              enable: checked,
            },
          },
        });

        const { errors, preReceiveSecretDetectionEnabled } = data.setPreReceiveSecretDetection;

        if (errors.length > 0) {
          this.reportError(errors[0].message);
        }
        if (preReceiveSecretDetectionEnabled !== null) {
          this.toggleValue = preReceiveSecretDetectionEnabled;
          this.$toast.show(
            preReceiveSecretDetectionEnabled
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
    notEnabled: s__('SecurityConfiguration|Not enabled'),
    availableWith: s__('SecurityConfiguration|Available with Ultimate'),
    learnMore: __('Learn more'),
    tooltipTitle: s__('SecretDetection|Action unavailable'),
    tooltipDescription: s__(
      'SecretDetection|This feature has been disabled at the instance level. Please reach out to your instance administrator to request activation.',
    ),
    accessLevelTooltipDescription: s__(
      'SecretDetection|Only a project maintainer or owner can toggle this feature.',
    ),
    toastMessageEnabled: s__('SecretDetection|Secret push protection is enabled'),
    toastMessageDisabled: s__('SecretDetection|Secret push protection is disabled'),
    settingsButtonTooltip: s__('SecretDetection|Configure Secret Detection'),
  },
};
</script>

<template>
  <gl-card :class="cardClasses">
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
              <span class="gl-text-success">{{ $options.i18n.enabled }}</span>
            </span>
          </template>

          <template v-else-if="available">
            <span>{{ $options.i18n.notEnabled }}</span>
          </template>

          <template v-else>
            {{ $options.i18n.availableWith }}
          </template>
        </div>
      </div>
    </template>

    <p class="gl-mb-0" :class="textClasses">
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
          :value="toggleValue"
          :label="s__('SecurityConfiguration|Toggle secret push protection')"
          label-position="hidden"
          @change="toggleSecretPushProtection"
        />
        <gl-button
          v-gl-tooltip.left.viewport="$options.i18n.settingsButtonTooltip"
          icon="settings"
          category="secondary"
          :href="secretDetectionConfigurationPath"
        />
      </div>
    </template>
  </gl-card>
</template>
