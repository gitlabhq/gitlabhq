<script>
  export default {
    name: 'SidebarDetailRow',
    props: {
      title: {
        type: String,
        required: false,
        default: '',
      },
      value: {
        type: String,
        required: true,
      },
    },
    computed: {
      hasTitle() {
        return this.title.length > 0;
      },
    },
  };
</script>
<template>
  <p class="build-detail-row">
    <span
      v-if="hasTitle"
      class="build-light-text"
    >
      {{ title }}:
    </span>
    {{ value }}
  </p>
</template>
