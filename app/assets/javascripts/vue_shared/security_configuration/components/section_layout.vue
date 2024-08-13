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
  <div class="row gl-border-b gl-m-0 gl-py-6 gl-leading-20">
    <div class="col-lg-4 gl-pl-0 gl-pr-9">
      <h2 class="gl-mt-0 gl-text-size-h2">{{ heading }}</h2>
      <slot name="description"></slot>
    </div>
    <div class="col-lg-8 gl-pl-0 gl-pr-0">
      <section-loader v-if="isLoading" />
      <slot v-else name="features"></slot>
    </div>
  </div>
</template>
