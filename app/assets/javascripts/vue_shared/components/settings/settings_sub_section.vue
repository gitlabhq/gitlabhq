<script>
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'SettingsSubSection',
  mixins: [glSlotsMixin],
  props: {
    heading: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasHeading() {
      return this.glSlots().heading || this.heading;
    },
    hasDescription() {
      return this.glSlots().description || this.description;
    },
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <div v-if="hasHeading || hasDescription" class="gl-mb-5">
      <h3
        v-if="hasHeading"
        class="gl-heading-3 !gl-mb-3"
        data-testid="settings-sub-section-heading"
      >
        <slot name="heading">
          {{ heading }}
        </slot>
      </h3>
      <p
        v-if="hasDescription"
        class="gl-max-w-88 gl-text-subtle"
        data-testid="settings-sub-section-description"
      >
        <slot name="description">
          {{ description }}
        </slot>
      </p>
    </div>
    <div class="gl-mt-3">
      <slot></slot>
    </div>
  </div>
</template>
