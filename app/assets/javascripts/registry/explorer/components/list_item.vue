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
    last: {
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
        'gl-border-t-1': !this.first,
        'gl-border-t-2': this.first,
        'gl-border-b-1': !this.last,
        'gl-border-b-2': this.last,
        'disabled-content': this.disabled,
        'gl-border-gray-200': !this.selected,
        'gl-bg-blue-50 gl-border-blue-200': this.selected,
      };
    },
  },
  mounted() {
    this.detailsSlots = Object.keys(this.$slots).filter(k => k.startsWith('details_'));
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
    class="gl-display-flex gl-flex-direction-column gl-border-b-solid gl-border-t-solid"
    :class="optionalClasses"
  >
    <div class="gl-display-flex gl-align-items-center gl-py-4 gl-px-2">
      <div
        v-if="$slots['left-action']"
        class="gl-w-7 gl-display-none gl-display-sm-flex gl-justify-content-start gl-pl-2"
      >
        <slot name="left-action"></slot>
      </div>
      <div class="gl-display-flex gl-flex-direction-column gl-flex-fill-1">
        <div
          class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-text-black-normal gl-font-weight-bold"
        >
          <div class="gl-display-flex gl-align-items-center">
            <slot name="left-primary"></slot>
            <gl-button
              v-if="detailsSlots.length > 0"
              :selected="isDetailsShown"
              icon="ellipsis_h"
              size="small"
              class="gl-ml-2"
              @click="toggleDetails"
            />
          </div>
          <div>
            <slot name="right-primary"></slot>
          </div>
        </div>
        <div
          class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-font-sm gl-text-gray-500"
        >
          <div>
            <slot name="left-secondary"></slot>
          </div>
          <div>
            <slot name="right-secondary"></slot>
          </div>
        </div>
      </div>
      <div
        v-if="$slots['right-action']"
        class="gl-w-9 gl-display-none gl-display-sm-flex gl-justify-content-end gl-pr-2"
      >
        <slot name="right-action"></slot>
      </div>
    </div>
    <div class="gl-display-flex">
      <div class="gl-w-7"></div>
      <div
        v-if="isDetailsShown"
        class="gl-display-flex gl-flex-direction-column gl-flex-fill-1 gl-bg-gray-10 gl-rounded-base gl-inset-border-1-gray-200 gl-mb-3"
      >
        <div
          v-for="(row, detailIndex) in detailsSlots"
          :key="detailIndex"
          class="gl-px-5 gl-py-2"
          :class="{
            'gl-border-gray-200 gl-border-t-solid gl-border-t-1': detailIndex !== 0,
          }"
        >
          <slot :name="row"></slot>
        </div>
      </div>
      <div class="gl-w-9"></div>
    </div>
  </div>
</template>
