<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'ListItem',
  components: { GlButton },
  props: {
    first: {
      type: Boolean,
      default: false,
      required: false,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
    selected: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      isDetailsShown: false,
      detailsSlots: [],
    };
  },
  computed: {
    optionalClasses() {
      return {
        'gl-border-t-transparent': !this.first && !this.selected,
        'gl-border-t-gray-100': this.first && !this.selected,
        'gl-opacity-5': this.disabled,
        'gl-border-b-gray-100': !this.selected,
        'gl-bg-blue-50 gl-border-blue-200': this.selected,
      };
    },
  },
  mounted() {
    this.detailsSlots = Object.keys(this.$slots).filter((k) => k.startsWith('details-'));
  },
  methods: {
    toggleDetails() {
      this.isDetailsShown = !this.isDetailsShown;
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-flex-direction-column gl-border-b-solid gl-border-t-solid gl-border-t-1 gl-border-b-1"
    :class="optionalClasses"
  >
    <div class="gl-display-flex gl-align-items-center gl-py-3 gl-px-5">
      <div
        v-if="$slots['left-action']"
        class="gl-w-7 gl-display-none gl-sm-display-flex gl-justify-content-start gl-pl-2"
      >
        <slot name="left-action"></slot>
      </div>
      <div
        class="gl-display-flex gl-xs-flex-direction-column gl-justify-content-space-between gl-align-items-stretch gl-flex-grow-1"
      >
        <div class="gl-display-flex gl-flex-direction-column gl-xs-mb-3 gl-min-w-0 gl-flex-grow-1">
          <div
            v-if="$slots['left-primary']"
            class="gl-display-flex gl-align-items-center gl-text-body gl-font-weight-bold gl-min-h-6 gl-min-w-0"
          >
            <slot name="left-primary"></slot>
            <gl-button
              v-if="detailsSlots.length > 0"
              :selected="isDetailsShown"
              icon="ellipsis_h"
              size="small"
              class="gl-ml-2 gl-display-none gl-sm-display-block"
              @click="toggleDetails"
            />
          </div>
          <div
            v-if="$slots['left-secondary']"
            class="gl-display-flex gl-align-items-center gl-text-gray-500 gl-min-h-6 gl-min-w-0 gl-flex-grow-1"
          >
            <slot name="left-secondary"></slot>
          </div>
        </div>
        <div
          class="gl-display-flex gl-flex-direction-column gl-sm-align-items-flex-end gl-justify-content-space-between gl-text-gray-500 gl-flex-shrink-0"
        >
          <div
            v-if="$slots['right-primary']"
            class="gl-display-flex gl-align-items-center gl-sm-text-body gl-sm-font-weight-bold gl-min-h-6"
          >
            <slot name="right-primary"></slot>
          </div>
          <div
            v-if="$slots['right-secondary']"
            class="gl-display-flex gl-align-items-center gl-min-h-6"
          >
            <slot name="right-secondary"></slot>
          </div>
        </div>
      </div>
      <div
        v-if="$slots['right-action']"
        class="gl-w-9 gl-display-none gl-sm-display-flex gl-justify-content-end gl-pr-1"
      >
        <slot name="right-action"></slot>
      </div>
    </div>
    <div class="gl-display-flex">
      <div class="gl-w-7"></div>
      <div
        v-if="isDetailsShown"
        class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-bg-gray-10 gl-rounded-base gl-inset-border-1-gray-100 gl-mb-3"
      >
        <div
          v-for="(row, detailIndex) in detailsSlots"
          :key="detailIndex"
          class="gl-px-5 gl-py-2"
          :class="{
            'gl-border-gray-100 gl-border-t-solid gl-border-t-1': detailIndex !== 0,
          }"
        >
          <slot :name="row"></slot>
        </div>
      </div>
      <div class="gl-w-9"></div>
    </div>
  </div>
</template>
