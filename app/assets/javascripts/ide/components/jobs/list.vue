<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import Stage from './stage.vue';

export default {
  components: {
    Stage,
    GlLoadingIcon,
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
    <gl-loading-icon v-if="loading && !stages.length" size="lg" class="gl-mt-3" />
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
