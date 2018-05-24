<script>
import { mapState } from 'vuex';
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';
import Stage from './stage.vue';

export default {
  components: {
    LoadingIcon,
    Stage,
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
  },
  computed: {
    ...mapState('pipelines', ['isLoadingJobs']),
  },
};
</script>

<template>
  <div>
    <loading-icon
      v-if="isLoadingJobs && !stages.length"
      class="prepend-top-default"
      size="2"
    />
    <template v-else>
      <stage
        v-for="stage in stages"
        :key="stage.id"
        :stage="stage"
      />
    </template>
  </div>
</template>
