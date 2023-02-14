<script>
export default {
  inject: {
    jobStatuses: {
      default: null,
    },
    url: {
      default: '',
    },
    emptyStateSvgPath: {
      default: '',
    },
  },
};
</script>

<template>
  <div>{{ __('Jobs') }}</div>
</template>
