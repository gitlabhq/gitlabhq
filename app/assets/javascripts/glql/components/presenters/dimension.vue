<script>
export default {
  name: 'DimensionPresenter',
  props: {
    data: {
      required: true,
      type: Object,
      validator: (value) => {
        return value.title;
      },
    },
  },
};
</script>
<template>
  <strong>{{ data.title }}</strong>
</template>
