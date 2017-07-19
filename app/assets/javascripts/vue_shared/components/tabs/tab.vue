<script>
  export default {
    name: 'tab',
    props: {
      title: {
        type: String,
        required: false,
      },
      headerHtml: {
        type: String,
        required: false,
        default: null,
      },
      tabId: {
        type: String,
        required: false,
        default: null,
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
