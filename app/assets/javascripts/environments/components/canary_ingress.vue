<script>
import { GlDropdown, GlDropdownItem, GlModalDirective as GlModal } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__ } from '~/locale';
import { CANARY_UPDATE_MODAL } from '../constants';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  directives: {
    GlModal,
  },
  props: {
    canaryIngress: {
      required: true,
      type: Object,
    },
  },
  ingressOptions: Array(100 / 5 + 1)
    .fill(0)
    .map((_, i) => i * 5),

  translations: {
    stableLabel: s__('CanaryIngress|Stable'),
    canaryLabel: s__('CanaryIngress|Canary'),
  },

  CANARY_UPDATE_MODAL,

  css: {
    label: [
      'gl-font-base',
      'gl-font-weight-normal',
      'gl-line-height-normal',
      'gl-inset-border-1-gray-200',
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
    stableWeight() {
      return (100 - this.canaryIngress.canary_weight).toString();
    },
    canaryWeight() {
      return this.canaryIngress.canary_weight.toString();
    },
  },
  methods: {
    changeCanary(weight) {
      this.$emit('change', weight);
    },
    changeStable(weight) {
      this.$emit('change', 100 - weight);
    },
  },
};
</script>
<template>
  <section class="gl-display-flex gl-bg-white gl-m-3">
    <div class="gl-display-flex gl-flex-direction-column">
      <label :for="stableWeightId" :class="$options.css.label" class="gl-rounded-top-left-base">
        {{ $options.translations.stableLabel }}
      </label>
      <gl-dropdown
        :id="stableWeightId"
        :text="stableWeight"
        data-testid="stable-weight"
        class="gl-w-full"
        toggle-class="gl-rounded-top-left-none! gl-rounded-top-right-none! gl-rounded-bottom-right-none!"
      >
        <gl-dropdown-item
          v-for="option in $options.ingressOptions"
          :key="option"
          v-gl-modal="$options.CANARY_UPDATE_MODAL"
          @click="changeStable(option)"
          >{{ option }}</gl-dropdown-item
        >
      </gl-dropdown>
    </div>
    <div class="gl-display-flex gl-display-flex gl-flex-direction-column">
      <label :for="canaryWeightId" :class="$options.css.label" class="gl-rounded-top-right-base">{{
        $options.translations.canaryLabel
      }}</label>
      <gl-dropdown
        :id="canaryWeightId"
        :text="canaryWeight"
        data-testid="canary-weight"
        toggle-class="gl-rounded-top-left-none! gl-rounded-top-right-none! gl-rounded-bottom-left-none! gl-border-l-none!"
      >
        <gl-dropdown-item
          v-for="option in $options.ingressOptions"
          :key="option"
          v-gl-modal="$options.CANARY_UPDATE_MODAL"
          @click="changeCanary(option)"
          >{{ option }}</gl-dropdown-item
        >
      </gl-dropdown>
    </div>
  </section>
</template>
