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
  <input :name="name" :value="value" type="hidden" />
</template>
