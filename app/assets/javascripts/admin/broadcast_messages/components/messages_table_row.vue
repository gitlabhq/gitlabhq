<script>
export default {
  name: 'MessagesTableRow',
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    {{ message.id }}
  </div>
</template>
