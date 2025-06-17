<script>
import { GlCard, GlIcon, GlLink, GlButton } from '@gitlab/ui';
import ManageViaMr from '~/vue_shared/security_configuration/components/manage_via_mr.vue';

export default {
  name: 'PipelineSecretDetectionFeatureCard',
  components: {
    GlCard,
    GlIcon,
    GlLink,
    GlButton,
    ManageViaMr,
  },
  inject: ['projectFullPath'],
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
    cardClasses() {
      return { 'gl-bg-strong': !this.available };
    },
    textClasses() {
      return { 'gl-text-subtle': !this.available };
    },
    statusClasses() {
      const { enabled } = this;

      return {
        'gl-text-disabled': !enabled,
        'gl-text-success': enabled,
      };
    },
    hyphenatedFeature() {
      return this.feature.type.replace(/_/g, '-');
    },
    showManageViaMr() {
      return ManageViaMr.canRender(this.feature);
    },
  },
  methods: {
    onError(message) {
      this.$emit('error', message);
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
          :data-qa-feature="`${feature.type}_${enabled}_status`"
        >
          <template v-if="enabled">
            <gl-icon name="check-circle-filled" />
            <span class="gl-text-success">{{ s__('SecurityConfiguration|Enabled') }}</span>
          </template>

          <template v-else-if="available">
            <span>{{ s__('SecurityConfiguration|Not enabled') }}</span>
          </template>
        </div>
      </div>
    </template>

    <p class="gl-mb-0" :class="textClasses">
      {{ feature.description }}
      <gl-link :href="feature.helpPath" target="_blank">{{ __('Learn more') }}.</gl-link>
    </p>

    <template v-if="available">
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
    </template>
  </gl-card>
</template>
