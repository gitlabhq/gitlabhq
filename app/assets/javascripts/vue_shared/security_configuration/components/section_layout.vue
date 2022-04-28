<script>
import SectionLoader from './section_loader.vue';

export default {
  name: 'SectionLayout',
  components: {
    SectionLoader,
  },
  props: {
    heading: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="row gl-m-0 gl-border-b gl-line-height-20 gl-py-6">
    <div class="col-lg-4 gl-pl-0 gl-pr-9">
      <h2 class="gl-font-size-h2 gl-mt-0">{{ heading }}</h2>
      <slot name="description"></slot>
    </div>
    <div class="col-lg-8 gl-pr-0 gl-pl-0">
      <section-loader v-if="isLoading" />
      <slot v-else name="features"></slot>
    </div>
  </div>
</template>
