<script>
import { GlLink, GlIcon, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlLink,
    GlIcon,
    GlBadge,
  },
  mixins: [glFeatureFlagMixin()],
  i18n: {
    premiumTitle: s__('ClusterAgents|Premium'),
  },
  props: {
    text: {
      required: true,
      type: String,
    },
    icon: {
      required: false,
      type: String,
      default: 'information',
    },
    iconClass: {
      required: false,
      type: String,
      default: 'text-info',
    },
    helpUrl: {
      required: false,
      type: String,
      default: null,
    },
    featureName: {
      required: false,
      type: String,
      default: null,
    },
  },
  computed: {
    showPremiumBadge() {
      return this.featureName && !this.glFeatures[this.featureName];
    },
  },
};
</script>

<template>
  <li class="gl-mb-3">
    <gl-icon :name="icon" :size="16" :class="iconClass" class="gl-mr-2" />

    <gl-link v-if="helpUrl" :href="helpUrl">{{ text }}</gl-link>
    <span v-else>{{ text }}</span>

    <gl-badge
      v-if="showPremiumBadge"
      class="gl-ml-2 gl-align-middle"
      icon="license"
      variant="tier"
      >{{ $options.i18n.premiumTitle }}</gl-badge
    >
  </li>
</template>
