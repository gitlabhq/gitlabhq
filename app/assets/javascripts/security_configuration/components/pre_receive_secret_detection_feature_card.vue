<script>
import { GlCard, GlIcon, GlLink, GlPopover, GlToggle, GlAlert } from '@gitlab/ui';
import ProjectSetPreReceiveSecretDetection from '~/security_configuration/graphql/set_pre_receive_secret_detection.graphql';
import BetaBadge from '~/vue_shared/components/badges/beta_badge.vue';
import { __, s__ } from '~/locale';

export default {
  name: 'PreReceiveSecretDetectionFeatureCard',
  components: {
    GlCard,
    GlIcon,
    GlLink,
    GlPopover,
    GlToggle,
    GlAlert,
    BetaBadge,
  },
  inject: [
    'preReceiveSecretDetectionAvailable',
    'preReceiveSecretDetectionEnabled',
    'userIsProjectAdmin',
    'projectFullPath',
  ],
  props: {
    feature: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      toggleValue: this.preReceiveSecretDetectionEnabled,
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
      return { 'gl-bg-gray-10': !this.available };
    },
    statusClasses() {
      const { enabled } = this;

      return {
        'gl-ml-auto': true,
        'gl-flex-shrink-0': true,
        'gl-text-gray-500': !enabled,
        'gl-text-green-500': enabled,
        'gl-w-full': true,
        'gl-justify-content-space-between': true,
        'gl-display-flex': true,
        'gl-mb-4': true,
      };
    },
    isToggleDisabled() {
      return !this.preReceiveSecretDetectionAvailable || !this.userIsProjectAdmin;
    },
    showLock() {
      return this.isToggleDisabled && this.available;
    },
    featureLockDescription() {
      if (!this.preReceiveSecretDetectionAvailable) {
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
    async togglePreReceiveSecretDetection(checked) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: ProjectSetPreReceiveSecretDetection,
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
    tooltipTitle: s__('SecretDetection|Feature not available'),
    tooltipDescription: s__(
      'SecretDetection|This feature has been disabled at the instance level. Please reach out to your instance administrator to request activation.',
    ),
    accessLevelTooltipDescription: s__(
      'SecretDetection|Only a project maintainer or owner can toggle this feature.',
    ),
    toastMessageEnabled: s__('SecretDetection|Secret push protection is enabled'),
    toastMessageDisabled: s__('SecretDetection|Secret push protection is disabled'),
  },
};
</script>

<template>
  <gl-card :class="cardClasses">
    <div class="gl-display-flex gl-align-items-baseline gl-flex-direction-column-reverse">
      <h3 class="gl-font-lg gl-m-0 gl-mr-3">
        {{ feature.name }}
        <gl-icon v-if="showLock" id="lockIcon" name="lock" class="gl-mb-1" />
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
        <beta-badge size="sm" />

        <template v-if="enabled">
          <span>
            <gl-icon name="check-circle-filled" />
            <span class="gl-text-green-700">{{ $options.i18n.enabled }}</span>
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

    <p class="gl-mb-0 gl-mt-5">
      {{ feature.description }}
      <gl-link :href="feature.helpPath" target="_blank">{{ $options.i18n.learnMore }}</gl-link>
    </p>

    <template v-if="available">
      <gl-alert
        v-if="shouldShowAlert"
        class="gl-mb-5 gl-mt-2"
        variant="danger"
        @dismiss="isAlertDismissed = true"
        >{{ errorMessage }}</gl-alert
      >
      <gl-toggle
        class="gl-mt-5"
        :disabled="isToggleDisabled"
        :value="toggleValue"
        :label="s__('SecurityConfiguration|Toggle secret push protection')"
        label-position="hidden"
        @change="togglePreReceiveSecretDetection"
      />
    </template>
  </gl-card>
</template>
