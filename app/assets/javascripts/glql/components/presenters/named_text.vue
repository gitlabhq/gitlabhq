<script>
export default {
  name: 'NamedTextPresenter',
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
};
</script>
<template>
  <span>{{ data.name }}</span>
</template>
