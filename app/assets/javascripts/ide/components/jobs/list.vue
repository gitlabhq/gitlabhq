<script>
import Stage from './stage.vue';

export default {
  components: {
    Stage,
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div style="overflow: auto;">
    <stage
      v-for="stage in stages"
      :key="stage.id"
      :stage="stage"
    />
  </div>
</template>
