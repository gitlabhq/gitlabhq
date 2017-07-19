<script>
  export default {
    name: 'tab',
    props: {
      title: {
        type: String,
        required: true
      },
    },
    data() {
      return {
        isActive: false,
      };
    }
  };
</script>
<template>
  <div
    v-show="isActive"
    class="tab-pannel"
    role="tabpanel">
    <slot></slot>
  </div>
</template>
