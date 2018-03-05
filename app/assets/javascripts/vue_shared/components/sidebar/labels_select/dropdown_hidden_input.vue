<script>
export default {
  props: {
    name: {
      type: String,
      required: true,
    },
    label: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <input
    type="hidden"
    :name="name"
    :value="label.id"
  />
</template>
