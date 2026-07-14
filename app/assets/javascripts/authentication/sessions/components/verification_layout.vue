<script>
export default {
  name: 'VerificationLayout',
  props: {
    svgPath: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-mx-auto gl-mt-5 gl-max-w-62">
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-attribute-strings -->
    <img :src="svgPath" alt="" class="gl-mx-auto gl-mb-5 gl-block" />
    <h2 class="gl-heading-2 gl-text-center">{{ title }}</h2>
    <p v-if="$scopedSlots.description" class="gl-text-subtle">
      <slot name="description"></slot>
    </p>
    <slot></slot>
  </div>
</template>
