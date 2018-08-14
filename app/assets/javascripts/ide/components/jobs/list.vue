<script>
import { mapActions } from 'vuex';
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
    <loading-icon
      v-if="loading && !stages.length"
      class="prepend-top-default"
      size="2"
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
