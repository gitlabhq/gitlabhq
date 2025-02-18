<script>
import { GlButton, GlCard, GlIcon, GlLink } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import ManageViaMr from '~/vue_shared/security_configuration/components/manage_via_mr.vue';
import FeatureCardBadge from './feature_card_badge.vue';

export default {
  components: {
    GlButton,
    GlCard,
    GlIcon,
    GlLink,
    FeatureCardBadge,
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
    shortName() {
      return this.feature.shortName ?? this.feature.name;
    },
    configurationButton() {
      const button = this.enabled
        ? {
            text: this.$options.i18n.configureFeature,
          }
        : {
            text: this.$options.i18n.enableFeature,
          };

      button.category = this.feature.category || 'secondary';
      button.text = sprintf(button.text, { feature: this.shortName });

      return button;
    },
    manageViaMrButtonCategory() {
      return this.feature.category || 'secondary';
    },
    showManageViaMr() {
      return ManageViaMr.canRender(this.feature);
    },
    cardClasses() {
      return { 'gl-bg-strong': !this.available };
    },
    textClasses() {
      return { 'gl-text-subtle': !this.available };
    },
    statusClasses() {
      const { enabled, hasBadge } = this;

      return {
        'gl-ml-auto': true,
        'gl-shrink-0': true,
        'gl-text-disabled': !enabled,
        'gl-text-success': enabled,
        'gl-w-full': hasBadge,
        'gl-justify-between': hasBadge,
        'gl-flex': hasBadge,
        'gl-mb-4': hasBadge,
      };
    },
    hasSecondary() {
      return Boolean(this.feature.secondary);
    },
    hasBadge() {
      const shouldDisplay = this.available || this.feature.badge?.alwaysDisplay;
      return Boolean(shouldDisplay && this.feature.badge?.text);
    },
    showSecondaryConfigurationHelpPath() {
      return Boolean(this.available && this.feature.secondary?.configurationHelpPath);
    },
    hyphenatedFeature() {
      return this.feature.type.replace(/_/g, '-');
    },
  },
  methods: {
    onError(message) {
      this.$emit('error', message);
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
    <template #header>
      <div class="gl-flex gl-items-baseline" :class="{ 'gl-flex-col-reverse': hasBadge }">
        <h3 class="gl-m-0 gl-mr-3 gl-text-base" :class="textClasses">
          {{ feature.name }}
        </h3>
        <div
          :class="statusClasses"
          data-testid="feature-status"
          :data-qa-feature="`${feature.type}_${enabled}_status`"
        >
          <feature-card-badge
            v-if="hasBadge"
            :badge="feature.badge"
            :badge-href="feature.badge.badgeHref"
          />

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
      <gl-link :href="feature.helpPath">{{ $options.i18n.learnMore }}.</gl-link>
    </p>

    <template v-if="available">
      <gl-button
        v-if="feature.configurationPath"
        :href="feature.configurationPath"
        variant="confirm"
        :category="configurationButton.category"
        :data-testid="`${hyphenatedFeature}-enable-button`"
        class="gl-mt-5"
      >
        {{ configurationButton.text }}
      </gl-button>

      <manage-via-mr
        v-else-if="showManageViaMr"
        :feature="feature"
        variant="confirm"
        :category="manageViaMrButtonCategory"
        class="gl-mt-5"
        :data-testid="`${hyphenatedFeature}-mr-button`"
        @error="onError"
      />

      <gl-button
        v-else-if="feature.configurationHelpPath"
        icon="external-link"
        :href="feature.configurationHelpPath"
        class="gl-mt-5"
      >
        {{ $options.i18n.configurationGuide }}
      </gl-button>
    </template>

    <div v-if="hasSecondary" data-testid="secondary-feature">
      <h4 class="gl-m-0 gl-mt-6 gl-text-base" :class="textClasses">
        {{ feature.secondary.name }}
      </h4>

      <p class="gl-mb-0 gl-mt-5" :class="textClasses">{{ feature.secondary.description }}</p>

      <gl-button
        v-if="available && feature.secondary.configurationPath"
        :href="feature.secondary.configurationPath"
        variant="confirm"
        category="secondary"
        class="gl-mt-5"
      >
        {{ feature.secondary.configurationText }}
      </gl-button>

      <gl-button
        v-else-if="showSecondaryConfigurationHelpPath"
        icon="external-link"
        :href="feature.secondary.configurationHelpPath"
        category="secondary"
        class="gl-mt-5"
      >
        {{ $options.i18n.configurationGuide }}
      </gl-button>
    </div>
  </gl-card>
</template>
