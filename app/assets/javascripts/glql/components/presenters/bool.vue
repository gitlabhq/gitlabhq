<script>
export default {
  name: 'BoolPresenter',
  props: {
    data: {
      required: true,
      type: Boolean,
    },
  },
};
</script>
<template>
  <span>{{ data ? __('Yes') : __('No') }}</span>
</template>
