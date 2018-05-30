<script>
export default {
  props: {
    name: {
      type: String,
      required: true,
    },
    value: {
      type: [Number, String],
      required: true,
    },
  },
};
</script>

<template>
  <input
    type="hidden"
    :name="name"
    :value="value"
  />
</template>
