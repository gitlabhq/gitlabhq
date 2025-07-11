<script>
export default {
  name: 'CodePresenter',
  props: {
    data: {
      required: true,
      type: String,
    },
  },
};
</script>
<template>
  <code>{{ data }}</code>
</template>
