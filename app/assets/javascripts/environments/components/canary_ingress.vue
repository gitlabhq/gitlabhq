<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import { s__ } from '~/locale';
import { CANARY_UPDATE_MODAL } from '../constants';

export default {
  components: {
    GlCollapsibleListbox,
  },
  props: {
    canaryIngress: {
      required: true,
      type: Object,
    },
    graphql: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  ingressOptions: Array(100 / 5 + 1)
    .fill(0)
    .map((_, i) => {
      const value = i * 5;
      return { value, text: value.toString() };
    }),
  translations: {
    stableLabel: s__('CanaryIngress|Stable'),
    canaryLabel: s__('CanaryIngress|Canary'),
  },

  CANARY_UPDATE_MODAL,

  css: {
    label: [
      'gl-text-base',
      'gl-font-normal',
      'gl-leading-normal',
      'gl-shadow-inner-1-dropdown',
      'gl-py-3',
      'gl-px-4',
      'gl-mb-0',
    ],
  },
  computed: {
    stableWeightId() {
      return uniqueId('stable-weight-');
    },
    canaryWeightId() {
      return uniqueId('canary-weight-');
    },
    weight() {
      if (this.graphql) {
        return this.canaryIngress.canaryWeight;
      }
      return this.canaryIngress.canary_weight;
    },
    stableWeight() {
      return 100 - this.weight;
    },
    canaryWeight() {
      return this.weight;
    },
  },
  methods: {
    changeCanary(weight) {
      this.$root.$emit('bv::show::modal', CANARY_UPDATE_MODAL);
      this.$emit('change', weight);
    },
    changeStable(weight) {
      this.$root.$emit('bv::show::modal', CANARY_UPDATE_MODAL);
      this.$emit('change', 100 - weight);
    },
  },
};
</script>
<template>
  <section class="gl-m-3 gl-flex gl-bg-white">
    <div class="gl-flex gl-flex-col">
      <label :for="stableWeightId" :class="$options.css.label" class="gl-rounded-tl-base">
        {{ $options.translations.stableLabel }}
      </label>
      <gl-collapsible-listbox
        :id="stableWeightId"
        :selected="stableWeight"
        :items="$options.ingressOptions"
        class="gl-min-w-full gl-text-default"
        toggle-class="gl-min-w-full !gl-rounded-tl-none !gl-rounded-tr-none !gl-rounded-br-none"
        @select="changeStable"
      />
    </div>
    <div class="gl-flex gl-flex-col">
      <label :for="canaryWeightId" :class="$options.css.label" class="gl-rounded-tr-base">{{
        $options.translations.canaryLabel
      }}</label>
      <gl-collapsible-listbox
        :id="canaryWeightId"
        :selected="canaryWeight"
        :items="$options.ingressOptions"
        class="gl-min-w-full"
        toggle-class="gl-min-w-full !gl-rounded-tl-none !gl-rounded-tr-none !gl-rounded-br-none"
        @select="changeCanary"
      />
    </div>
  </section>
</template>
