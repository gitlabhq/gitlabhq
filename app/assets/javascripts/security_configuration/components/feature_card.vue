<script>
import { GlButton, GlCard, GlIcon, GlLink } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import ManageViaMr from '~/vue_shared/security_configuration/components/manage_via_mr.vue';

export default {
  components: {
    GlButton,
    GlCard,
    GlIcon,
    GlLink,
    ManageViaMr,
  },
  props: {
    feature: {
      type: Object,
      required: true,
    },
  },
  computed: {
    available() {
      return this.feature.available;
    },
    enabled() {
      return this.available && this.feature.configured;
    },
    hasStatus() {
      return !this.available || typeof this.feature.configured === 'boolean';
    },
    shortName() {
      return this.feature.shortName ?? this.feature.name;
    },
    configurationButton() {
      const button = this.enabled
        ? {
            text: this.$options.i18n.configureFeature,
            category: 'secondary',
          }
        : {
            text: this.$options.i18n.enableFeature,
            category: 'primary',
          };

      button.text = sprintf(button.text, { feature: this.shortName });

      return button;
    },
    showManageViaMr() {
      return ManageViaMr.canRender(this.feature);
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
      };
    },
    hasSecondary() {
      const { name, description, configurationText } = this.feature.secondary ?? {};
      return Boolean(name && description && configurationText);
    },
  },
  i18n: {
    enabled: s__('SecurityConfiguration|Enabled'),
    notEnabled: s__('SecurityConfiguration|Not enabled'),
    availableWith: s__('SecurityConfiguration|Available with Ultimate'),
    configurationGuide: s__('SecurityConfiguration|Configuration guide'),
    configureFeature: s__('SecurityConfiguration|Configure %{feature}'),
    enableFeature: s__('SecurityConfiguration|Enable %{feature}'),
    learnMore: __('Learn more'),
  },
};
</script>

<template>
  <gl-card :class="cardClasses">
    <div class="gl-display-flex gl-align-items-baseline">
      <h3 class="gl-font-lg gl-m-0 gl-mr-3">{{ feature.name }}</h3>

      <div :class="statusClasses" data-testid="feature-status">
        <template v-if="hasStatus">
          <template v-if="enabled">
            <gl-icon name="check-circle-filled" />
            <span class="gl-text-green-700">{{ $options.i18n.enabled }}</span>
          </template>

          <template v-else-if="available">
            {{ $options.i18n.notEnabled }}
          </template>

          <template v-else>
            {{ $options.i18n.availableWith }}
          </template>
        </template>
      </div>
    </div>

    <p class="gl-mb-0 gl-mt-5">
      {{ feature.description }}
      <gl-link :href="feature.helpPath">{{ $options.i18n.learnMore }}</gl-link>
    </p>

    <template v-if="available">
      <gl-button
        v-if="feature.configurationPath"
        :href="feature.configurationPath"
        variant="confirm"
        :category="configurationButton.category"
        class="gl-mt-5"
      >
        {{ configurationButton.text }}
      </gl-button>

      <manage-via-mr
        v-else-if="showManageViaMr"
        :feature="feature"
        variant="confirm"
        category="primary"
        class="gl-mt-5"
      />

      <gl-button v-else icon="external-link" :href="feature.configurationHelpPath" class="gl-mt-5">
        {{ $options.i18n.configurationGuide }}
      </gl-button>
    </template>

    <div v-if="hasSecondary" data-testid="secondary-feature">
      <h4 class="gl-font-base gl-m-0 gl-mt-6">{{ feature.secondary.name }}</h4>

      <p class="gl-mb-0 gl-mt-5">{{ feature.secondary.description }}</p>

      <gl-button
        v-if="available && feature.secondary.configurationPath"
        :href="feature.secondary.configurationPath"
        variant="confirm"
        category="secondary"
        class="gl-mt-5"
      >
        {{ feature.secondary.configurationText }}
      </gl-button>
    </div>
  </gl-card>
</template>
