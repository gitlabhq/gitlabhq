<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ListItem',
  components: { GlButton },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
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
        'gl-border-t-default': this.first && !this.selected,
        'gl-border-b-default': !this.selected,
        '!gl-border-t-transparent': this.selected && !this.first,
        'gl-bg-blue-50 gl-border-blue-200': this.selected,
      };
    },
    toggleDetailsIcon() {
      return this.isDetailsShown ? 'chevron-up' : 'chevron-down';
    },
    toggleDetailsLabel() {
      return this.isDetailsShown ? __('Hide details') : __('Show details');
    },
  },
  mounted() {
    // eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots
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
    class="gl-flex gl-flex-col gl-border-b-1 gl-border-t-1 gl-border-b-solid gl-border-t-solid"
    :class="optionalClasses"
  >
    <div class="gl-flex gl-items-center gl-py-3">
      <div
        v-if="$slots['left-action'] /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */"
        class="gl-flex gl-w-7 gl-justify-start gl-pl-2"
      >
        <slot name="left-action"></slot>
      </div>
      <div class="gl-flex gl-grow gl-flex-col gl-items-stretch gl-justify-between sm:gl-flex-row">
        <div class="gl-mb-3 gl-flex gl-min-w-0 gl-grow gl-flex-col sm:gl-mb-0">
          <div
            v-if="
              $slots['left-primary'] /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */
            "
            class="gl-flex gl-min-h-6 gl-min-w-0 gl-items-center gl-font-semibold gl-text-default"
          >
            <slot name="left-primary"></slot>
            <gl-button
              v-if="detailsSlots.length > 0"
              v-gl-tooltip
              :icon="toggleDetailsIcon"
              :aria-label="toggleDetailsLabel"
              size="small"
              class="gl-ml-2 gl-hidden sm:gl-block"
              category="tertiary"
              :title="toggleDetailsLabel"
              :aria-expanded="isDetailsShown"
              @click="toggleDetails"
            />
            <slot name="left-after-toggle"></slot>
          </div>
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'left-secondary'
              ]
            "
            class="gl-flex gl-min-h-6 gl-min-w-0 gl-grow gl-items-center gl-gap-3 gl-text-sm gl-text-subtle"
          >
            <slot name="left-secondary"></slot>
          </div>
        </div>
        <div
          class="gl-flex gl-shrink-0 gl-flex-col gl-justify-between gl-text-subtle sm:gl-items-end"
        >
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'right-primary'
              ]
            "
            class="gl-flex gl-min-h-6 gl-items-center sm:gl-text-default"
          >
            <slot name="right-primary"></slot>
          </div>
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'right-secondary'
              ]
            "
            class="gl-flex gl-min-h-6 gl-items-center gl-text-sm"
          >
            <slot name="right-secondary"></slot>
          </div>
        </div>
      </div>
      <div
        v-if="
          $slots['right-action'] /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */
        "
        class="gl-flex gl-w-9 gl-justify-end gl-pr-1"
      >
        <slot name="right-action"></slot>
      </div>
    </div>
    <div v-if="isDetailsShown" class="gl-flex">
      <div class="gl-w-7"></div>
      <div
        class="gl-mb-3 gl-flex gl-grow gl-flex-col gl-rounded-base gl-bg-subtle gl-shadow-inner-1-gray-100"
      >
        <div
          v-for="(row, detailIndex) in detailsSlots"
          :key="detailIndex"
          class="gl-px-5 gl-py-2"
          :class="{
            'gl-border-t-1 gl-border-default gl-border-t-solid': detailIndex !== 0,
          }"
        >
          <slot :name="row"></slot>
        </div>
      </div>
      <div class="gl-w-9"></div>
    </div>
  </div>
</template>
