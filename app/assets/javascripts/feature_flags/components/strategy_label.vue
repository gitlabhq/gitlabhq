<script>
export default {
  props: {
    name: {
      type: String,
      required: true,
    },
    scopes: {
      type: String,
      required: false,
      default: null,
    },
    parameters: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>
<template>
  <div>
    <strong class="gl-fw-bold"
      >{{ name }}<span v-if="parameters"> - {{ parameters }}</span
      >:</strong
    >
    <span v-if="scopes">{{ scopes }}</span>
  </div>
</template>
