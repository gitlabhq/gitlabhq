<script>
export default {
  name: 'TextPresenter',
  props: {
    data: {
      required: true,
      type: [String, Number],
    },
  },
};
</script>
<template>
  <span>{{ data }}</span>
</template>
