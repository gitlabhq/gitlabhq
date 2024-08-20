<script>
export default {
  name: 'CollectionPresenter',
  inject: ['presenter'],
  props: {
    data: {
      required: true,
      type: Object,
      validator: ({ nodes }) => Array.isArray(nodes),
    },
  },
};
</script>
<template>
  <span>
    <div v-for="(field, index) in data.nodes" :key="index" class="gl-inline-block gl-pr-2">
      <component :is="presenter.forField(field)" />
    </div>
  </span>
</template>
