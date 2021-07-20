<script>
export default {
  name: 'SectionLayout',
  props: {
    heading: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="row gl-line-height-20">
    <div class="col-lg-4">
      <h2 class="gl-font-size-h2 gl-mt-0">{{ heading }}</h2>
      <slot name="description"></slot>
    </div>
    <div class="col-lg-8">
      <slot name="features"></slot>
    </div>
  </div>
</template>
