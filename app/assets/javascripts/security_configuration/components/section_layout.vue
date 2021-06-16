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
  <div class="row">
    <div class="col-lg-5">
      <h2 class="gl-font-size-h2 gl-mt-0">{{ heading }}</h2>
      <slot name="description"></slot>
    </div>
    <div class="col-lg-7">
      <slot name="features"></slot>
    </div>
  </div>
</template>
