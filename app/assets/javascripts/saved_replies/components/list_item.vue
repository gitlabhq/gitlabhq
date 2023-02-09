<script>
export default {
  props: {
    reply: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <li class="gl-mb-5">
    <div class="gl-display-flex gl-align-items-center">
      <strong>{{ reply.name }}</strong>
    </div>
    <div class="gl-mt-3 gl-font-monospace">{{ reply.content }}</div>
  </li>
</template>
