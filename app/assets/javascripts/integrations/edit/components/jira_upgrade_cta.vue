<script>
import { GlButton, GlCard } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlCard,
  },
  props: {
    upgradePlanPath: {
      type: String,
      required: false,
      default: '',
    },
    showPremiumMessage: {
      type: Boolean,
      required: false,
      default: false,
    },
    showUltimateMessage: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    title() {
      return this.showUltimateMessage
        ? this.$options.i18n.titleUltimate
        : this.$options.i18n.titlePremium;
    },
  },
  i18n: {
    titleUltimate: s__('JiraService|This is an Ultimate feature'),
    titlePremium: s__('JiraService|This is a Premium feature'),
    content: s__('JiraService|Upgrade your plan to enable this feature of the Jira Integration.'),
    upgrade: __('Upgrade your plan'),
  },
};
</script>

<template>
  <gl-card>
    <strong>{{ title }}</strong>
    <p>{{ $options.i18n.content }}</p>
    <gl-button v-if="upgradePlanPath" category="primary" variant="info" :href="upgradePlanPath">
      {{ $options.i18n.upgrade }}
    </gl-button>
  </gl-card>
</template>
