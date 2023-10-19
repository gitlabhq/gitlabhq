<script>
export default {
  name: 'ShowMlModelApp',
  components: {},
  props: {
    model: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>{{ model.name }}</div>
</template>
