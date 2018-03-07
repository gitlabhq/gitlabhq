<script>
  export default {
    name: 'MRWidgetMaintainerEdit',
    props: {
      maintainerEditAllowed: {
        type: Boolean,
        default: false,
        required: false,
      },
    },
  };
</script>

<template>
  <section class="mr-info-list mr-links">
    <p v-if="maintainerEditAllowed">
      {{ s__("mrWidget|Allows edits from maintainers") }}
    </p>
  </section>
</template>
