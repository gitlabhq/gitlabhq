<script>
export default {
  name: 'PercentagePresenter',
  props: {
    data: {
      required: true,
      type: Number,
    },
  },
  computed: {
    formattedPercentage() {
      const value = this.data * 100;
      const formatted = value % 1 === 0 ? value.toFixed(0) : value.toFixed(1);
      return `${formatted}%`;
    },
  },
};
</script>
<template>
  <span>{{ formattedPercentage }}</span>
</template>
