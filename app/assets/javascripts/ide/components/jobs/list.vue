<script>
import { mapActions } from 'vuex';
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
    loading: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    ...mapActions('pipelines', ['fetchJobs', 'toggleStageCollapsed', 'setDetailJob']),
  },
};
</script>

<template>
  <div>
    <gl-loading-icon
      v-if="loading && !stages.length"
      :size="2"
      class="prepend-top-default"
    />
    <template v-else>
      <stage
        v-for="stage in stages"
        :key="stage.id"
        :stage="stage"
        @fetch="fetchJobs"
        @toggleCollapsed="toggleStageCollapsed"
        @clickViewLog="setDetailJob"
      />
    </template>
  </div>
</template>
