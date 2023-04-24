<script>
export default {
  props: {
    option: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <span
    >{{ option.title }}
    <span class="title-hint-text">&lt;{{ __('yyyy-mm-dd') }}&gt;</span>
  </span>
</template>
