<script>
import tooltip from '~/vue_shared/directives/tooltip';
import icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'IssueCardWeight',
  components: {
    icon,
  },
  directives: {
    tooltip,
  },
  props: {
    weight: {
      type: Number,
      required: true,
    },
  },
};
</script>

<template>
  <span
    class="card-weight card-number prepend-left-5"
    v-tooltip
    data-container="body"
    data-placement="bottom"
    :title="__('Weight')"
  >
    <icon name="scale" />
    {{ weight }}
  </span>
</template>
