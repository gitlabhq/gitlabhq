<script>
import PageHeading from './page_heading.vue';

export default {
  name: 'IndexLayout',
  components: {
    PageHeading,
  },
  props: {
    heading: {
      type: String,
      required: false,
      default: null,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    pageHeadingSrOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-5">
    <page-heading
      :heading="heading"
      class="!gl-my-0 gl-pt-5"
      :class="{ 'gl-sr-only': pageHeadingSrOnly }"
    >
      <template v-if="$scopedSlots.heading" #heading>
        <slot name="heading"></slot>
      </template>
      <template v-if="$scopedSlots.actions" #actions>
        <slot name="actions"></slot>
      </template>
      <template v-if="$scopedSlots.description || description" #description>
        <slot v-if="$scopedSlots.description" name="description"></slot>
        <template v-else>{{ description }}</template>
      </template>
    </page-heading>
    <div
      v-if="$scopedSlots.alerts"
      class="gl-flex gl-flex-col gl-gap-3"
      data-testid="index-layout-alerts"
    >
      <slot name="alerts"></slot>
    </div>
    <div data-testid="index-layout-content">
      <slot></slot>
    </div>
  </div>
</template>
