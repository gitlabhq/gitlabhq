<script>
export default {
  props: {
    count: {
      type: Number,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-col-span-full gl-text-subtle">
    {{ n__('%d draft hidden', '%d drafts hidden', count) }}
  </div>
</template>
