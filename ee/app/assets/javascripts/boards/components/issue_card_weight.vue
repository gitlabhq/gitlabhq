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
    v-tooltip
    :title="__('Weight')"
    class="board-card-weight card-number d-inline-block"
    data-container="body"
    data-placement="bottom"
  >
    <icon name="scale" />
    {{ weight }}
  </span>
</template>
