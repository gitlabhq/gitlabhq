<script>
export default {
  props: {
    duration: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="log-duration-badge rounded align-self-start px-2 ml-2 flex-shrink-0 ws-normal">
    {{ duration }}
  </div>
</template>
